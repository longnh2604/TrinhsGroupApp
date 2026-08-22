<?php
/**
 * Plugin Name: Trinh Push Notifications
 * Description: Sends FCM push notifications when WooCommerce order status changes.
 * Version: 1.4.0
 */

if (!defined('ABSPATH')) exit;

// ─── Path to your Firebase service account JSON ───────────────────────────────
define('TRINH_SA_PATH', ABSPATH . 'firebase-service-account.json');

// ─── REST API: register/update FCM token ──────────────────────────────────────
// Requires a valid JWT (Authorization: Bearer <token>). The device is always bound
// to the token's own user — a caller cannot register a token against someone else.
add_action('rest_api_init', function () {
    register_rest_route('trinh-app/v1', '/fcm/register', [
        'methods'             => 'POST',
        'callback'            => 'trinh_register_fcm_token',
        'permission_callback' => 'trinh_require_authenticated_user',
    ]);

    register_rest_route('trinh-app/v1', '/fcm/unregister', [
        'methods'             => 'POST',
        'callback'            => 'trinh_unregister_fcm_token',
        'permission_callback' => 'trinh_require_authenticated_user',
    ]);
});

function trinh_require_authenticated_user() {
    if (!is_user_logged_in()) {
        return new WP_Error(
            'trinh_not_authenticated',
            'Authentication required.',
            ['status' => 401]
        );
    }
    return true;
}

function trinh_register_fcm_token(WP_REST_Request $request) {
    // Never trust a user_id from the request body — derive it from the JWT.
    $user_id   = get_current_user_id();
    $fcm_token = sanitize_text_field($request->get_param('fcm_token'));

    if (!$fcm_token) {
        return new WP_Error('missing_params', 'fcm_token is required.', ['status' => 400]);
    }

    // A device belongs to exactly one account. Clearing the token from every other user
    // first is what stops the previous account keeping this device: logging out does not
    // always reach /fcm/unregister — the session-expiry and checkout-expiry logout paths
    // have no valid JWT left to authenticate with — so registration has to heal it.
    // Without this, both accounts hold the same token and the device gets pushes for both.
    trinh_forget_fcm_token($fcm_token, 'reassigned to user ' . $user_id);

    update_user_meta($user_id, '_trinh_fcm_token', $fcm_token);

    return rest_ensure_response(['success' => true, 'user_id' => $user_id]);
}

/**
 * Unbind a device on logout, so order pushes for the account that just signed out stop
 * arriving. Clears by token rather than by user: the caller proves possession of the
 * device via its own JWT, and the token may still be attached to a stale account.
 */
function trinh_unregister_fcm_token(WP_REST_Request $request) {
    $user_id   = get_current_user_id();
    $fcm_token = sanitize_text_field($request->get_param('fcm_token'));

    if (!$fcm_token) {
        return new WP_Error('missing_params', 'fcm_token is required.', ['status' => 400]);
    }

    $cleared = trinh_forget_fcm_token($fcm_token, 'unregistered by user ' . $user_id);

    return rest_ensure_response(['success' => true, 'cleared' => $cleared]);
}

// ─── WooCommerce hook: status changed ─────────────────────────────────────────
add_action('woocommerce_order_status_changed', 'trinh_on_order_status_changed', 10, 4);

function trinh_on_order_status_changed($order_id, $old_status, $new_status, $order) {
    $customer_id = $order->get_customer_id();
    if (!$customer_id) return; // guest order, skip

    $fcm_token = get_user_meta($customer_id, '_trinh_fcm_token', true);
    if (!$fcm_token) return;

    // 'on-hold' is the status the app creates pay-on-pickup orders in, so the customer
    // has just placed it — "Order Received" is what they should see. A second 'on-hold'
    // entry ("Order On Hold") used to sit at the end of this array and silently won,
    // because a duplicate PHP array key overwrites the earlier one.
    $messages = [
        'on-hold'    => ['title' => 'Order Received',    'body'  => "Order #{$order_id} is awaiting payment."],
        'processing' => ['title' => 'Order Confirmed',   'body'  => "Order #{$order_id} is being prepared!"],
        'completed'  => ['title' => 'Order Ready! 🎉',   'body'  => "Order #{$order_id} is complete. Thank you!"],
        'cancelled'  => ['title' => 'Order Cancelled',   'body'  => "Order #{$order_id} has been cancelled."],
        'refunded'   => ['title' => 'Order Refunded',    'body'  => "Order #{$order_id} has been refunded."],
    ];

    if (!isset($messages[$new_status])) return;

    $payload = $messages[$new_status];
    trinh_send_fcm($fcm_token, $payload['title'], $payload['body'], [
        'order_id' => (string) $order_id,
        'status'   => $new_status,
    ]);
}

// ─── Send FCM via HTTP v1 API ─────────────────────────────────────────────────
function trinh_send_fcm(string $token, string $title, string $body, array $data = []) {
    $sa = json_decode(file_get_contents(TRINH_SA_PATH), true);
    if (!$sa) {
        error_log('[Trinh FCM] Failed to read service account JSON.');
        return;
    }

    $project_id   = $sa['project_id'];
    $access_token = trinh_get_oauth_token($sa);
    if (!$access_token) return;

    // No top-level 'notification' block, deliberately. With one present, Android's FCM SDK
    // draws the tray notification itself and onMessageReceived is never called while the app
    // is backgrounded — so the app never learns the order_id, and the entry it recovers from
    // the tray (syncTrayNotifications) has nothing to open. iOS does not have that problem:
    // getDeliveredNotifications() hands the whole data block back as userInfo.
    //
    // So each platform is told separately. Android reads title/body out of 'data' and posts
    // the notification itself, on its own channel and with the order_id attached; iOS reads
    // aps.alert, which is exactly what FCM used to synthesise from the notification block —
    // same wire format, no app change. 'priority' => 'high' is required, not decoration: a
    // data-only message at normal priority can sit in Doze until the device wakes.
    $message = [
        'message' => [
            'token'   => $token,
            'data'    => $data + ['title' => $title, 'body' => $body],
            'android' => ['priority' => 'high'],
            'apns'    => [
                'headers' => ['apns-priority' => '10'],
                'payload' => [
                    'aps' => [
                        'alert' => ['title' => $title, 'body' => $body],
                        'sound' => 'default',
                        'badge' => 1,
                    ],
                ],
            ],
        ],
    ];

    $url      = "https://fcm.googleapis.com/v1/projects/{$project_id}/messages:send";
    $response = wp_remote_post($url, [
        'headers' => [
            'Authorization' => "Bearer {$access_token}",
            'Content-Type'  => 'application/json',
        ],
        'body'    => json_encode($message),
        'timeout' => 15,
    ]);

    if (is_wp_error($response)) {
        error_log('[Trinh FCM] cURL error: ' . $response->get_error_message());
        return;
    }

    // Only transport errors used to be logged. A message FCM *rejected* — an unregistered
    // device token, a malformed payload, an expired key — came back as a perfectly good
    // HTTP response carrying an error body, and was discarded without a trace. That makes
    // "customers stopped getting notifications" impossible to diagnose from the server.
    $code = (int) wp_remote_retrieve_response_code($response);
    $body = wp_remote_retrieve_body($response);

    if ($code < 200 || $code >= 300) {
        $decoded = json_decode($body, true);
        $status  = $decoded['error']['status']  ?? '';
        $detail  = $decoded['error']['message'] ?? $body;
        error_log(sprintf(
            '[Trinh FCM] send failed for order %s: HTTP %d %s — %s',
            $data['order_id'] ?? '?',
            $code,
            $status,
            $detail
        ));

        // UNREGISTERED / INVALID_ARGUMENT on the token means this device is gone for good
        // (app deleted, or token rotated). Drop it so we stop retrying on every status
        // change; the app re-registers via trinh-app/v1/fcm/register on next launch.
        if (in_array($status, ['UNREGISTERED', 'NOT_FOUND'], true)) {
            trinh_forget_fcm_token($token);
        }
        return;
    }

    error_log(sprintf(
        '[Trinh FCM] sent for order %s: %s',
        $data['order_id'] ?? '?',
        trim($body)
    ));
}

/**
 * Detach a device token from every account holding it.
 *
 * Called for three reasons: FCM reported the token dead, the app signed out, or another
 * account claimed the same device. Clearing across all users — not just one — is the point:
 * a token left on a stale account keeps pushing that account's orders to someone else's
 * phone.
 *
 * @param string $token  The device token.
 * @param string $reason Logged so the three callers stay distinguishable.
 * @return int Number of accounts the token was removed from.
 */
function trinh_forget_fcm_token(string $token, string $reason = 'reported dead by FCM'): int {
    $users = get_users([
        'meta_key'   => '_trinh_fcm_token',
        'meta_value' => $token,
        'fields'     => 'ID',
        'number'     => 5,
    ]);
    foreach ($users as $user_id) {
        delete_user_meta($user_id, '_trinh_fcm_token', $token);
        error_log("[Trinh FCM] cleared token for user {$user_id} ({$reason})");
    }
    return count($users);
}

// ─── Generate OAuth2 Bearer token from service account (pure PHP, no library) ─
function trinh_get_oauth_token(array $sa): ?string {
    $now    = time();
    $header = trinh_base64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
    $claim  = trinh_base64url(json_encode([
        'iss'   => $sa['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud'   => 'https://oauth2.googleapis.com/token',
        'iat'   => $now,
        'exp'   => $now + 3600,
    ]));

    $to_sign = "{$header}.{$claim}";
    $key     = openssl_pkey_get_private($sa['private_key']);
    if (!$key) {
        error_log('[Trinh FCM] Failed to load private key.');
        return null;
    }

    openssl_sign($to_sign, $signature, $key, 'SHA256');
    $jwt = "{$to_sign}." . trinh_base64url($signature);

    $response = wp_remote_post('https://oauth2.googleapis.com/token', [
        'body'    => http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $jwt,
        ]),
        'timeout' => 15,
    ]);

    if (is_wp_error($response)) return null;

    $body = json_decode(wp_remote_retrieve_body($response), true);
    return $body['access_token'] ?? null;
}

function trinh_base64url(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

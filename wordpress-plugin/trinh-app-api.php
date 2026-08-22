<?php
/**
 * Plugin Name: Trinh App API
 * Description: JWT-scoped REST endpoints for the TrinhsGroup iOS app. Replaces the app's
 *              direct WooCommerce consumer-key access to customer, order, coupon and
 *              payment-gateway data, so the shipped binary needs only a read-only key
 *              for public catalog reads.
 * Version: 1.3.0
 * Author: Trinh's Kitchen Group
 */

if (!defined('ABSPATH')) exit;

const TRINH_APP_NS = 'trinh-app/v1';

/** Order statuses the app is allowed to create. Anything else is an attempt to skip payment. */
const TRINH_APP_CREATABLE_STATUSES = ['pending', 'on-hold'];

// ─────────────────────────────────────────────────────────────────────────────
// Route registration
// ─────────────────────────────────────────────────────────────────────────────

add_action('rest_api_init', function () {

    // --- Own customer record ------------------------------------------------
    register_rest_route(TRINH_APP_NS, '/me', [
        [
            'methods'             => 'GET',
            'callback'            => 'trinh_app_get_me',
            'permission_callback' => 'trinh_app_require_auth',
        ],
        [
            'methods'             => 'PUT',
            'callback'            => 'trinh_app_update_me',
            'permission_callback' => 'trinh_app_require_auth',
        ],
        [
            'methods'             => 'DELETE',
            'callback'            => 'trinh_app_delete_me',
            'permission_callback' => 'trinh_app_require_auth',
        ],
    ]);

    // --- Own orders ---------------------------------------------------------
    register_rest_route(TRINH_APP_NS, '/me/orders', [
        [
            'methods'             => 'GET',
            'callback'            => 'trinh_app_list_my_orders',
            'permission_callback' => 'trinh_app_require_auth',
        ],
        [
            'methods'             => 'POST',
            'callback'            => 'trinh_app_create_my_order',
            'permission_callback' => 'trinh_app_require_auth',
        ],
    ]);

    // What the basket would cost, priced by the server. POST because it carries the basket.
    register_rest_route(TRINH_APP_NS, '/me/orders/preview', [
        'methods'             => 'POST',
        'callback'            => 'trinh_app_preview_my_order',
        'permission_callback' => 'trinh_app_require_auth',
    ]);

    register_rest_route(TRINH_APP_NS, '/me/orders/(?P<id>\d+)/cancel', [
        'methods'             => 'POST',
        'callback'            => 'trinh_app_cancel_my_order',
        'permission_callback' => 'trinh_app_require_auth',
        'args'                => [
            'id' => ['sanitize_callback' => 'absint'],
        ],
    ]);

    register_rest_route(TRINH_APP_NS, '/me/orders/(?P<id>\d+)/history', [
        'methods'             => 'GET',
        'callback'            => 'trinh_app_get_my_order_history',
        'permission_callback' => 'trinh_app_require_auth',
        'args'                => [
            'id' => ['sanitize_callback' => 'absint'],
        ],
    ]);

    register_rest_route(TRINH_APP_NS, '/me/orders/(?P<id>\d+)/payment-intent', [
        'methods'             => 'GET',
        'callback'            => 'trinh_app_get_my_payment_intent',
        'permission_callback' => 'trinh_app_require_auth',
        'args'                => [
            'id' => ['sanitize_callback' => 'absint'],
        ],
    ]);

    // --- Own redeemed vouchers ---------------------------------------------
    register_rest_route(TRINH_APP_NS, '/me/vouchers', [
        'methods'             => 'GET',
        'callback'            => 'trinh_app_list_my_vouchers',
        'permission_callback' => 'trinh_app_require_auth',
    ]);

    // --- Enabled payment gateways ------------------------------------------
    register_rest_route(TRINH_APP_NS, '/payment-methods', [
        'methods'             => 'GET',
        'callback'            => 'trinh_app_list_payment_methods',
        'permission_callback' => 'trinh_app_require_auth',
    ]);

    // --- Add-on definitions, mirroring what the product page offers -------------
    register_rest_route(TRINH_APP_NS, '/products/(?P<id>\d+)/addons', [
        'methods'             => 'GET',
        'callback'            => 'trinh_app_get_product_addons',
        'permission_callback' => '__return_true',
    ]);

    // --- Public signup (the one write that happens before a JWT exists) ----
    register_rest_route(TRINH_APP_NS, '/register', [
        'methods'             => 'POST',
        'callback'            => 'trinh_app_register_customer',
        'permission_callback' => '__return_true',
    ]);
});

// ─────────────────────────────────────────────────────────────────────────────
// Auth helpers
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Every /me route resolves its subject from the JWT, never from client input.
 * The jwt-authentication-for-wp-rest-api plugin hooks determine_current_user, so a valid
 * `Authorization: Bearer <token>` populates get_current_user_id().
 */
function trinh_app_require_auth() {
    if (!is_user_logged_in()) {
        return new WP_Error('trinh_not_authenticated', 'Authentication required.', ['status' => 401]);
    }
    return true;
}

/**
 * Run an internal WooCommerce REST request with Woo's own permission gate bypassed.
 *
 * Callers MUST have already established that the authenticated user owns the resource —
 * this helper grants full Woo REST access for the duration of a single dispatch. Using
 * Woo's controllers (rather than hand-rolling JSON) keeps the response byte-shape
 * identical to what the iOS Codable models already expect.
 *
 * @param string $method
 * @param string $route
 * @param array  $body   JSON body for write requests.
 * @param array  $query  Query parameters.
 * @return WP_REST_Response|WP_Error
 */
function trinh_app_woo_dispatch(string $method, string $route, array $body = [], array $query = []) {
    $request = new WP_REST_Request($method, $route);

    foreach ($query as $key => $value) {
        $request->set_param($key, $value);
    }

    if (!empty($body)) {
        $request->set_header('Content-Type', 'application/json');
        $request->set_body(wp_json_encode($body));
    }

    add_filter('woocommerce_rest_check_permissions', '__return_true');
    $response = rest_do_request($request);
    remove_filter('woocommerce_rest_check_permissions', '__return_true');

    if ($response->is_error()) {
        return $response->as_error();
    }
    return $response;
}

// ─────────────────────────────────────────────────────────────────────────────
// /me — own customer record
// ─────────────────────────────────────────────────────────────────────────────

function trinh_app_get_me(WP_REST_Request $request) {
    return trinh_app_woo_dispatch('GET', '/wc/v3/customers/' . get_current_user_id());
}

/**
 * Fields the app may change on its own customer record. Anything outside this list —
 * `role`, `id`, `meta_data`, `username` — is dropped, so a customer cannot escalate
 * privileges or overwrite loyalty-point meta through their own profile screen.
 */
function trinh_app_update_me(WP_REST_Request $request) {
    $allowed_top    = ['email', 'first_name', 'last_name', 'password'];
    $allowed_nested = [
        'billing'  => ['first_name', 'last_name', 'company', 'country', 'address_1', 'address_2', 'city', 'postcode', 'state', 'email', 'phone'],
        'shipping' => ['first_name', 'last_name', 'company', 'country', 'address_1', 'address_2', 'city', 'postcode', 'state', 'phone'],
    ];

    $incoming = $request->get_json_params() ?: [];
    $body     = [];

    foreach ($allowed_top as $key) {
        if (isset($incoming[$key])) {
            $body[$key] = $incoming[$key];
        }
    }

    foreach ($allowed_nested as $group => $keys) {
        if (empty($incoming[$group]) || !is_array($incoming[$group])) {
            continue;
        }
        foreach ($keys as $key) {
            if (isset($incoming[$group][$key])) {
                $body[$group][$key] = sanitize_text_field((string) $incoming[$group][$key]);
            }
        }
    }

    if (isset($body['email'])) {
        $email = sanitize_email($body['email']);
        if (!is_email($email)) {
            return new WP_Error('trinh_invalid_email', 'A valid email address is required.', ['status' => 400]);
        }
        $existing = get_user_by('email', $email);
        if ($existing && (int) $existing->ID !== get_current_user_id()) {
            return new WP_Error('trinh_email_taken', 'That email address is already in use.', ['status' => 409]);
        }
        $body['email'] = $email;
    }

    if (empty($body)) {
        return new WP_Error('trinh_nothing_to_update', 'No updatable fields supplied.', ['status' => 400]);
    }

    return trinh_app_woo_dispatch('PUT', '/wc/v3/customers/' . get_current_user_id(), $body);
}

function trinh_app_delete_me(WP_REST_Request $request) {
    return trinh_app_woo_dispatch(
        'DELETE',
        '/wc/v3/customers/' . get_current_user_id(),
        [],
        ['force' => true, 'reassign' => 0]
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// /me/orders
// ─────────────────────────────────────────────────────────────────────────────

function trinh_app_list_my_orders(WP_REST_Request $request) {
    $per_page = min(100, max(1, absint($request->get_param('per_page') ?: 100)));
    $page     = max(1, absint($request->get_param('page') ?: 1));

    return trinh_app_woo_dispatch('GET', '/wc/v3/orders', [], [
        'customer' => get_current_user_id(),
        'per_page' => $per_page,
        'page'     => $page,
    ]);
}

/**
 * Create an order for the authenticated customer.
 *
 * Everything money-related is recomputed here. The client supplies only what it is
 * entitled to choose — which products, how many, notes, pickup time, payment method —
 * and the server derives customer, prices and status.
 */
function trinh_app_create_my_order(WP_REST_Request $request) {
    $user_id  = get_current_user_id();
    $incoming = $request->get_json_params() ?: [];

    $requested = trinh_app_validated_line_items($incoming);
    if (is_wp_error($requested)) {
        return $requested;
    }

    // --- Status: allowlisted so a client cannot self-serve a paid order -----------
    $status = sanitize_key($incoming['status'] ?? 'on-hold');
    if (!in_array($status, TRINH_APP_CREATABLE_STATUSES, true)) {
        return new WP_Error(
            'trinh_invalid_status',
            'Unsupported order status.',
            ['status' => 400]
        );
    }

    // --- Payment method must be a real, enabled gateway ---------------------------
    // Deliberately uses payment_gateways() (all registered) rather than
    // get_available_payment_gateways(), which calls each gateway's is_available() and
    // depends on cart/session state that does not exist on a REST request.
    $payment_method = sanitize_text_field($incoming['payment_method'] ?? '');
    if ($payment_method !== '' && !trinh_app_gateway_is_enabled($payment_method)) {
        return new WP_Error('trinh_invalid_payment_method', 'Unsupported payment method.', ['status' => 400]);
    }

    // --- Billing: seeded from the account, with contact details overridable -------
    $customer = new WC_Customer($user_id);
    $incoming_billing = (array) ($incoming['billing'] ?? []);
    $billing = [
        'first_name' => sanitize_text_field($incoming_billing['first_name'] ?? $customer->get_billing_first_name()),
        'last_name'  => sanitize_text_field($incoming_billing['last_name'] ?? $customer->get_billing_last_name()),
        'address_1'  => sanitize_text_field($incoming_billing['address_1'] ?? $customer->get_billing_address_1()),
        'city'       => sanitize_text_field($incoming_billing['city'] ?? $customer->get_billing_city()),
        'state'      => sanitize_text_field($incoming_billing['state'] ?? $customer->get_billing_state()),
        'postcode'   => sanitize_text_field($incoming_billing['postcode'] ?? $customer->get_billing_postcode()),
        'country'    => sanitize_text_field($incoming_billing['country'] ?? $customer->get_billing_country() ?: 'AU'),
        'phone'      => sanitize_text_field($incoming_billing['phone'] ?? $customer->get_billing_phone()),
        'email'      => sanitize_email($incoming_billing['email'] ?? $customer->get_billing_email() ?: $customer->get_email()),
    ];

    if (!is_email($billing['email'])) {
        return new WP_Error('trinh_invalid_billing_email', 'A valid billing email is required.', ['status' => 400]);
    }

    $coupon_code = trinh_app_requested_coupon($incoming, $user_id);
    if (is_wp_error($coupon_code)) {
        return $coupon_code;
    }

    $order_id = trinh_app_create_order_from_cart([
        'line_items'       => $requested['items'],
        'enforce_required' => $requested['enforce_required'],
        'status'           => $status,
        'payment_method'   => $payment_method,
        'payment_title'    => sanitize_text_field($incoming['payment_method_title'] ?? ''),
        'customer_note'    => sanitize_textarea_field($incoming['customer_note'] ?? ''),
        'billing'          => $billing,
        'order_meta'       => trinh_app_pickup_meta($incoming),
        'coupon_code'      => $coupon_code,
    ]);

    if (is_wp_error($order_id)) {
        return $order_id;
    }

    // Rendered by Woo's own orders controller, exactly as it rendered the old
    // POST /wc/v3/orders response, so the app's Codable models see no change.
    return trinh_app_woo_dispatch('GET', '/wc/v3/orders/' . $order_id);
}

/**
 * The add-on groups on offer for one product, as the website would offer them.
 *
 * Public, like the product page it mirrors, but the answer still depends on who is asking:
 * block visibility is filtered by login state and role. A caller that sends its JWT gets
 * exactly the groups the order endpoint will validate its choices against; a guest gets the
 * guest view. Both are self-consistent, which is what matters.
 */
function trinh_app_get_product_addons(WP_REST_Request $request) {
    $product_id   = absint($request->get_param('id'));
    $variation_id = absint($request->get_param('variation_id'));

    if (!wc_get_product($product_id)) {
        return new WP_Error('trinh_product_not_found', 'Product not found.', ['status' => 404]);
    }

    // YITH fires no hook when an add-on is saved — it has only yith_wapo_before/after_addons,
    // _show_options_shortcode, _after_add_order_item_meta and _migrated — so there is nothing
    // to bust this on and a short TTL is the honest ceiling on how stale it can be. The key
    // carries the caller's visibility context, or one role's groups would be served to another.
    $user      = wp_get_current_user();
    $cache_key = 'trinh_addons_' . md5(implode('|', [
        $product_id,
        $variation_id,
        is_user_logged_in() ? 'in' : 'out',
        implode(',', (array) $user->roles),
    ]));

    $cached = get_transient($cache_key);
    if (is_array($cached)) {
        return rest_ensure_response($cached);
    }

    $payload = [
        'product_id' => $product_id,
        'addons'     => array_map(
            'trinh_app_yith_addon_payload',
            trinh_app_yith_addons_for_product($product_id, $variation_id)
        ),
    ];

    set_transient($cache_key, $payload, 5 * MINUTE_IN_SECONDS);

    return rest_ensure_response($payload);
}

/**
 * Quote the basket the customer is looking at, so the checkout screen can show the total it
 * will actually be charged — add-ons priced by YITH, the 5% taken by the gateway fee.
 *
 * Creates nothing. Reads the same body as order creation, minus what only a real order needs
 * (status, billing, pickup time). Required add-on groups are checked here too: a basket that
 * cannot be ordered should not be quoted a price.
 */
function trinh_app_preview_my_order(WP_REST_Request $request) {
    $user_id  = get_current_user_id();
    $incoming = $request->get_json_params() ?: [];

    $requested = trinh_app_validated_line_items($incoming);
    if (is_wp_error($requested)) {
        return $requested;
    }

    // The gateway carries the fee, so it decides the quote as much as the basket does.
    $payment_method = sanitize_text_field($incoming['payment_method'] ?? '');
    if ($payment_method !== '' && !trinh_app_gateway_is_enabled($payment_method)) {
        return new WP_Error('trinh_invalid_payment_method', 'Unsupported payment method.', ['status' => 400]);
    }

    $coupon_code = trinh_app_requested_coupon($incoming, $user_id);
    if (is_wp_error($coupon_code)) {
        return $coupon_code;
    }

    $totals = trinh_app_preview_order_totals([
        'line_items'       => $requested['items'],
        'enforce_required' => $requested['enforce_required'],
        'payment_method'   => $payment_method,
        'coupon_code'      => $coupon_code,
    ]);

    return is_wp_error($totals) ? $totals : rest_ensure_response($totals);
}

/**
 * The line items the client is allowed to ask for: identity and quantity, plus add-on
 * selections. Any client-sent pricing is discarded — the server prices the order.
 *
 * Shared by ordering and quoting, so the two cannot disagree about what is orderable.
 *
 * @return array{items: array, enforce_required: bool}|WP_Error
 */
function trinh_app_validated_line_items(array $incoming) {
    $items = [];

    // A client that sends any yith_wapo selection speaks YITH's contract, so required
    // add-on groups are enforced across the whole order. Binaries already in customers'
    // hands send add-ons as meta_data text only; enforcing on those would reject every
    // order for a product that has a required group, so they keep today's behaviour.
    $enforce_required = false;

    foreach ((array) ($incoming['line_items'] ?? []) as $item) {
        $product_id = absint($item['product_id'] ?? 0);
        $quantity   = absint($item['quantity'] ?? 0);

        if ($product_id <= 0 || $quantity <= 0) {
            return new WP_Error('trinh_invalid_line_item', 'Each line item needs a product_id and a quantity.', ['status' => 400]);
        }

        $product = wc_get_product($product_id);
        if (!$product || !$product->is_purchasable()) {
            return new WP_Error(
                'trinh_product_unavailable',
                sprintf('Product %d is not available for purchase.', $product_id),
                ['status' => 400]
            );
        }

        $clean = [
            'product_id' => $product_id,
            'quantity'   => $quantity,
        ];

        if (!empty($item['variation_id'])) {
            $clean['variation_id'] = absint($item['variation_id']);
        }

        // meta_data carries the add-on selections (rice type, spice level…) — text only.
        if (!empty($item['meta_data']) && is_array($item['meta_data'])) {
            $metas = [];
            foreach ($item['meta_data'] as $meta) {
                if (!isset($meta['key'])) {
                    continue;
                }
                $value = $meta['value'] ?? '';
                $metas[] = [
                    'key'   => sanitize_text_field((string) $meta['key']),
                    'value' => is_scalar($value) ? sanitize_text_field((string) $value) : '',
                ];
            }
            if ($metas) {
                $clean['meta_data'] = $metas;
            }
        }

        // YITH add-on selections, in that plugin's own submit shape.
        $selections = trinh_app_yith_selections($item);
        if (is_wp_error($selections)) {
            return $selections;
        }
        if ($selections) {
            $clean['yith_wapo'] = $selections;
            $enforce_required   = true;
        }

        $items[] = $clean;
    }

    if (empty($items)) {
        return new WP_Error('trinh_empty_order', 'An order needs at least one line item.', ['status' => 400]);
    }

    return ['items' => $items, 'enforce_required' => $enforce_required];
}

/**
 * The voucher this request is asking for, once confirmed to be the caller's own.
 *
 * @return string|WP_Error
 */
function trinh_app_requested_coupon(array $incoming, int $user_id) {
    $code = sanitize_text_field($incoming['coupon_code'] ?? '');
    if ($code === '' && !empty($incoming['coupon_lines'][0]['code'])) {
        $code = sanitize_text_field($incoming['coupon_lines'][0]['code']);
    }
    if ($code !== '' && !trinh_app_user_owns_coupon($user_id, $code)) {
        return new WP_Error('trinh_coupon_not_yours', 'That voucher does not belong to this account.', ['status' => 403]);
    }

    return $code;
}

/**
 * Put the customer's basket in a real WooCommerce cart, hand the calculated cart to $finish,
 * and leave the session exactly as it was found.
 *
 * The cart is the only place YITH Product Add-ons charges for an add-on
 * (YITH_WAPO_Cart::add_cart_item, on woocommerce_add_cart_item) and the only place it
 * writes the choice the kitchen reads (add_order_item_meta, on woocommerce_new_order_item,
 * which reads WC_Order_Item_Product::$legacy_values — set solely by
 * WC_Checkout::create_order_line_items). Dispatching a pre-built body to /wc/v3/orders
 * reached neither hook, which is why app orders arrived with no choices and no add-on
 * charge. Prices are never computed here; YITH and the fee plugin compute them.
 *
 * Placing an order and quoting one both come through here, so the price the app shows and
 * the price it charges cannot drift apart.
 *
 * @param array    $args   line_items, enforce_required, payment_method, coupon_code, plus
 *                         whatever $finish reads.
 * @param callable $finish Run against the calculated cart; its return value is returned.
 * @return mixed|WP_Error
 */
function trinh_app_with_app_cart(array $args, callable $finish) {
    if (!function_exists('wc_load_cart') || !function_exists('WC')) {
        return new WP_Error('trinh_cart_unavailable', 'Ordering is temporarily unavailable.', ['status' => 503]);
    }

    wc_load_cart(); // REST has no cart or session of its own.

    if (!WC()->cart || !WC()->session) {
        return new WP_Error('trinh_cart_unavailable', 'Ordering is temporarily unavailable.', ['status' => 503]);
    }

    // The customer's website cart lives in this same session, and every add_to_cart()
    // rewrites both it and the persistent copy in user meta. Park the session cart and
    // switch the persistent copy off, so ordering in the app cannot empty the cart the
    // customer left on the website.
    $parked_cart = WC()->session->get('cart', null);
    add_filter('woocommerce_persistent_cart_enabled', '__return_false');

    // A cart, unlike the old pre-built body, calculates fees — and the app's 5% discount is
    // a negative gateway fee configured on the website (alg_gateways_fees_* for
    // other_payment, cash on pickup), computed on cart_contents_total, so after add-ons and
    // after vouchers. Going through the cart is what earns that discount back, with no rate
    // written into the app. checkout-fees-for-woocommerce reads the gateway from the session
    // and otherwise falls back to the store default (Alg_WC_Checkout_Fees::get_current_gateway),
    // so the customer's own choice has to be put there — the default gateway's fee would be
    // the wrong money. With no method chosen there is no gateway fee to apply.
    $parked_gateway = WC()->session->get('chosen_payment_method');
    if ($args['payment_method'] !== '') {
        WC()->session->set('chosen_payment_method', $args['payment_method']);
    } else {
        add_filter('alg_wc_add_default_gateway_on_cart', '__return_empty_string');
    }

    WC()->cart->empty_cart(false);
    wc_clear_notices();

    // A stale awaiting-payment id from an abandoned web checkout would let create_order()
    // resume that order instead of opening a new one. An app order is always new.
    WC()->session->set('order_awaiting_payment', null);

    try {
        foreach ($args['line_items'] as $item) {
            $added = trinh_app_add_cart_line($item, $args['enforce_required']);
            if (is_wp_error($added)) {
                return $added;
            }
        }

        // An expired or used-up voucher used to come back as a 400 from Woo's own orders
        // controller. Applying it to the cart must not quietly charge full price instead.
        if ($args['coupon_code'] !== '' && !WC()->cart->apply_coupon($args['coupon_code'])) {
            $notices = wc_get_notices('error');
            wc_clear_notices();

            return new WP_Error(
                'trinh_coupon_rejected',
                !empty($notices[0]['notice'])
                    ? wp_strip_all_tags($notices[0]['notice'])
                    : 'That voucher could not be applied.',
                ['status' => 400]
            );
        }

        WC()->cart->calculate_totals();

        return $finish();
    } finally {
        // Leave the session as it was found, whether or not an order was created.
        WC()->cart->empty_cart(false);
        WC()->session->set('cart', $parked_cart);
        WC()->session->set('chosen_payment_method', $parked_gateway);
        remove_filter('woocommerce_persistent_cart_enabled', '__return_false');
        remove_filter('alg_wc_add_default_gateway_on_cart', '__return_empty_string');
        wc_clear_notices();
    }
}

/**
 * Create the order from the cart and return its id.
 *
 * customer_id no longer has to be forced by hand: WC_Checkout::create_order() sets it from
 * the woocommerce_checkout_customer_id filter over get_current_user_id(), which the JWT
 * resolved. Nor does set_paid — this path never marks an order paid.
 *
 * @param array $args As trinh_app_with_app_cart, plus status, payment_title, customer_note,
 *                    billing and order_meta.
 * @return int|WP_Error
 */
function trinh_app_create_order_from_cart(array $args) {
    return trinh_app_with_app_cart($args, static function () use ($args) {
        $line_meta = static function ($item, $cart_item_key, $values) {
            // Pre-YITH clients still send add-ons and the note as line-item text.
            foreach ((array) ($values['trinh_app_meta'] ?? []) as $meta) {
                $item->add_meta_data($meta['key'], $meta['value']);
            }
        };
        $order_meta = static function ($order) use ($args) {
            // Stamped before the first save, so pickup details exist by the time the order's
            // status transition fires the push notification.
            foreach ((array) ($args['order_meta'] ?? []) as $entry) {
                $order->update_meta_data($entry['key'], $entry['value']);
            }
        };

        add_action('woocommerce_checkout_create_order_line_item', $line_meta, 10, 3);
        add_action('woocommerce_checkout_create_order', $order_meta, 10, 1);

        try {
            $data = [
                'status'               => $args['status'],
                'payment_method'       => $args['payment_method'],
                'payment_method_title' => $args['payment_title'],
                'order_comments'       => $args['customer_note'], // WC_Checkout's own key
            ];
            foreach ($args['billing'] as $field => $value) {
                $data['billing_' . $field] = $value;
            }

            $order_id = WC()->checkout()->create_order($data);

            if (is_wp_error($order_id)) {
                return new WP_Error('trinh_order_failed', $order_id->get_error_message(), ['status' => 400]);
            }

            return (int) $order_id;
        } finally {
            remove_action('woocommerce_checkout_create_order_line_item', $line_meta, 10);
            remove_action('woocommerce_checkout_create_order', $order_meta, 10);
        }
    });
}

/**
 * What the same basket would cost, without creating anything.
 *
 * The checkout screen cannot work this out for itself: add-on prices come from YITH and the
 * cash-on-pickup discount is a negative gateway fee, and neither exists until there is a
 * cart. Quoting through the same cart as ordering is what keeps the quoted total and the
 * charged total the same number.
 *
 * fee_lines carries the server's own labels, so the app renders whatever the website is
 * configured to charge — including the 5% — without holding a rate of its own.
 *
 * @return array|WP_Error
 */
function trinh_app_preview_order_totals(array $args) {
    return trinh_app_with_app_cart($args, static function () {
        $decimals = wc_get_price_decimals();

        $fee_lines = [];
        foreach (WC()->cart->get_fees() as $fee) {
            $fee_lines[] = [
                'name' => $fee->name,
                // ->total, not ->amount: WooCommerce clamps a negative fee so it cannot take
                // the order below zero and writes the clamped figure back (WC_Cart_Totals:323).
                // That is the figure create_order_fee_lines() puts on the order, so quoting
                // anything else could differ from the charge on a heavily discounted basket.
                'total' => wc_format_decimal($fee->total, $decimals),
            ];
        }

        return [
            'subtotal'       => wc_format_decimal(WC()->cart->get_subtotal(), $decimals),
            'discount_total' => wc_format_decimal(WC()->cart->get_discount_total(), $decimals),
            'fee_lines'      => $fee_lines,
            'total'          => wc_format_decimal(WC()->cart->get_total('edit'), $decimals),
        ];
    });
}

/**
 * Put one validated line in the cart, letting YITH price it.
 *
 * @return string|WP_Error Cart item key.
 */
function trinh_app_add_cart_line(array $item, bool $enforce_required) {
    $product_id   = $item['product_id'];
    $variation_id = $item['variation_id'] ?? 0;
    $selections   = $item['yith_wapo'] ?? [];

    if ($enforce_required) {
        $missing = trinh_app_yith_missing_required($product_id, $variation_id, $selections);
        if ($missing !== null) {
            return new WP_Error(
                'trinh_addon_required',
                sprintf('Please choose an option for “%s”.', $missing),
                ['status' => 400]
            );
        }
    }

    $cart_item_data = [];

    if ($selections && class_exists('YITH_WAPO_Cart')) {
        // YITH's own reader. $post_data is an explicit third parameter, so nothing has to
        // be forged into $_POST; yith_wapo_product_id must match the product or the
        // method bails (YITH_WAPO_Cart::add_cart_item_data).
        $post_data = [
            'yith_wapo_product_id' => $product_id,
            'yith_wapo'            => array_map(
                static function ($key, $value) {
                    return [$key => $value];
                },
                array_keys($selections),
                $selections
            ),
        ];

        $cart_item_data = YITH_WAPO_Cart::get_instance()->add_cart_item_data([], $product_id, $post_data);
    }

    if (!empty($item['meta_data'])) {
        $cart_item_data['trinh_app_meta'] = $item['meta_data'];
    }

    $cart_item_key = WC()->cart->add_to_cart($product_id, $item['quantity'], $variation_id, [], $cart_item_data);

    if (!$cart_item_key) {
        // add_to_cart() reports its refusals as notices rather than return values.
        $notices = wc_get_notices('error');
        wc_clear_notices();

        return new WP_Error(
            'trinh_line_item_rejected',
            !empty($notices[0]['notice'])
                ? wp_strip_all_tags($notices[0]['notice'])
                : 'That item could not be added to the order.',
            ['status' => 400]
        );
    }

    return $cart_item_key;
}

/**
 * Read the YITH add-on selections off an incoming line item.
 *
 * Accepted as a flat map, because every key is already unique in YITH's contract:
 *
 *     {"28": "0", "29": "1", "30-0": "1"}
 *
 * select and radio key the add-on and carry the chosen option in the value; checkbox keys
 * both and carries "1". Empty values are dropped rather than passed on — YITH renders
 * nothing for them, so keeping one would let a required group read as answered when the
 * customer chose nothing. "default" is dropped for the same reason: it is the value of the
 * unchosen placeholder in a select (templates/front/addons/select.php:34), and YITH writes no
 * meta for it (YITH_WAPO_Cart::add_order_item_meta skips 'default'), so honouring it would put
 * order 11690's pho-less Family Trio straight back.
 *
 * A malformed key is refused rather than skipped: silently dropping one would silently
 * drop what it charges for.
 *
 * @return array<string, string>|WP_Error
 */
function trinh_app_yith_selections(array $item) {
    $raw = $item['yith_wapo'] ?? null;

    if (!is_array($raw)) {
        return [];
    }

    $selections = [];

    foreach ($raw as $key => $value) {
        if (!preg_match('/^\d+(-\d+)?$/', (string) $key) || !is_scalar($value)) {
            return new WP_Error(
                'trinh_invalid_addon_selection',
                'Add-on selections must be keyed "<addon_id>" or "<addon_id>-<option_id>".',
                ['status' => 400]
            );
        }

        $clean = sanitize_text_field((string) $value);
        if ($clean !== '' && 'default' !== $clean) {
            $selections[(string) $key] = $clean;
        }
    }

    return $selections;
}

/**
 * Title of the first required add-on group these selections leave unanswered, or null.
 *
 * Enumerated the way the product page enumerates it — the blocks visible for this product,
 * then that block's visible add-ons — so a group hidden from this customer is never
 * demanded of them. The website enforces required groups, and the app must not become a
 * way around that: order 11690's Family Trio reached the kitchen with no pho chosen.
 */
function trinh_app_yith_missing_required(int $product_id, int $variation_id, array $selections): ?string {
    foreach (trinh_app_yith_addons_for_product($product_id, $variation_id) as $addon) {
        if ('yes' !== $addon->get_setting('required', 'no', false)) {
            continue;
        }

        // A group behind conditional logic may not be on screen at all, and its rules are
        // evaluated in the browser, not here. Demanding an answer we cannot know is owed
        // would reject baskets the website itself accepts.
        if ('yes' === $addon->get_setting('enable_rules', 'no', false)) {
            continue;
        }

        $addon_id = (string) $addon->get_id();
        $answered = false;

        foreach (array_keys($selections) as $key) {
            // "28" answers add-on 28; "30-0" answers add-on 30. Cast before comparing:
            // PHP int-ifies numeric JSON keys, and 28 === "28" is false — without the cast
            // every select/radio answer is invisible here and the group reads unanswered.
            $key = (string) $key;
            if ($key === $addon_id || strpos($key, $addon_id . '-') === 0) {
                $answered = true;
                break;
            }
        }

        if (!$answered) {
            return $addon->get_title();
        }
    }

    return null;
}

/**
 * The add-on groups the website would show this customer for this product, in display order.
 *
 * Enumerated the way the product page enumerates it — blocks visible for the product, then
 * that block's visible add-ons (YITH_WAPO_Front::print_addons). Note the block query filters
 * on login state, roles and membership plans, so the answer is per-customer, not per-product.
 *
 * @return array YITH_WAPO_Addon objects.
 */
function trinh_app_yith_addons_for_product(int $product_id, int $variation_id = 0): array {
    if (!function_exists('YITH_WAPO') || !isset(YITH_WAPO()->db)) {
        return [];
    }

    $addons = [];
    $blocks = YITH_WAPO()->db->yith_wapo_get_blocks_by_product($product_id, $variation_id ?: null, 'yes');

    foreach ((array) $blocks as $block_id) {
        foreach ((array) YITH_WAPO()->db->yith_wapo_get_addons_by_block_id($block_id, true) as $addon) {
            $addons[] = $addon;
        }
    }

    return $addons;
}

/**
 * One add-on group, in the shape the app needs to render it and to send a choice back.
 *
 * Every option carries the exact key and value to submit, because that shape depends on the
 * type: select and radio key the group and carry the choice in the value, checkbox keys both
 * and carries "1" (YITH_WAPO::split_addon_and_option_ids). Working that out in the app would
 * put one rule in two places, which is the shape of the bug this whole plan is about.
 *
 * @param object $addon YITH_WAPO_Addon.
 */
function trinh_app_yith_addon_payload($addon): array {
    $addon_id = (string) $addon->get_id();
    $type     = (string) $addon->get_setting('type', '');
    $decimals = wc_get_price_decimals();

    // Options are stored as parallel arrays, one per field, so the count is the length of any
    // one of them — the same way templates/front/block.php:213 works it out.
    $fields = (array) $addon->get_options();
    $first  = $fields ? array_values($fields)[0] : [];
    $total  = is_array($first) ? count($first) : 0;

    $options = [];

    for ($index = 0; $index < $total; $index++) {
        // The sale price when one is set, because that is the one the cart charges
        // (YITH_WAPO_Cart::add_order_item_meta prefers price_sale whenever it is not '').
        $sale  = trim((string) $addon->get_sale_price($index));
        $price = '' !== $sale ? $sale : (string) $addon->get_price($index);

        $options[] = [
            'option_id'    => (string) $index,
            'label'        => (string) $addon->get_option('label', $index, ''),
            // price_type says whether this is money or a percentage of the product price.
            'price'        => wc_format_decimal((float) str_replace(',', '.', $price), $decimals),
            'price_type'   => (string) $addon->get_option('price_type', $index, 'fixed', false),
            'price_method' => (string) $addon->get_option('price_method', $index, 'free', false),
            // The website pre-ticks this option — YITH's "selected by default", read the same
            // way templates/front/addons/checkbox.php:44 reads it. The app shows such an
            // option marked from the start and locked against unmarking.
            'default_checked' => 'yes' === $addon->get_option('default', $index, 'no', false),
            'submit_key'   => 'checkbox' === $type ? $addon_id . '-' . $index : $addon_id,
            'submit_value' => 'checkbox' === $type ? '1' : (string) $index,
        ];
    }

    $min = null;
    $max = null;

    if ('yes' === $addon->get_setting('enable_min_max', 'no', false)) {
        $rules  = (array) $addon->get_setting('min_max_rule', [], false);
        $values = (array) $addon->get_setting('min_max_value', [], false);

        foreach ($rules as $position => $rule) {
            if (!isset($values[$position])) {
                continue;
            }
            if ('min' === $rule) {
                $min = (int) $values[$position];
            } elseif ('max' === $rule) {
                $max = (int) $values[$position];
            }
        }
    }

    return [
        'addon_id'       => (int) $addon_id,
        'type'           => $type,
        'title'          => (string) $addon->get_title(),
        'description'    => (string) $addon->get_setting('description', ''),
        'required'       => 'yes' === $addon->get_setting('required', 'no', false),
        'selection_type' => (string) $addon->get_setting('selection_type', 'single', false),
        // True means the website decides in the browser whether this group is shown at all.
        // Nothing here evaluates those rules, and the required check skips such groups.
        'conditional'    => 'yes' === $addon->get_setting('enable_rules', 'no', false),
        'min'            => $min,
        'max'            => $max,
        'options'        => $options,
    ];
}

function trinh_app_gateway_is_enabled(string $gateway_id): bool {
    if (!function_exists('WC') || !WC()->payment_gateways()) {
        return false;
    }
    $gateways = WC()->payment_gateways()->payment_gateways();
    return isset($gateways[$gateway_id]) && 'yes' === $gateways[$gateway_id]->enabled;
}

/**
 * Pickup date/time meta, matching the keys the CodeRockz delivery plugin reads.
 */
function trinh_app_pickup_meta(array $incoming): array {
    $pickup = sanitize_text_field($incoming['pickup_datetime'] ?? '');

    foreach ((array) ($incoming['meta_data'] ?? []) as $meta) {
        if (($meta['key'] ?? '') === 'pickup_datetime' && $pickup === '') {
            $pickup = sanitize_text_field((string) ($meta['value'] ?? ''));
        }
    }

    if ($pickup === '') {
        return [];
    }

    $meta = [['key' => 'pickup_datetime', 'value' => $pickup]];

    $timestamp = strtotime($pickup);
    if ($timestamp) {
        $meta[] = ['key' => '_pi_delivery_date', 'value' => wp_date('Y-m-d', $timestamp)];
        $meta[] = ['key' => '_pi_delivery_time', 'value' => wp_date('H:i', $timestamp)];
        $meta[] = ['key' => '_pi_delivery_type', 'value' => 'pickup'];
    }

    return $meta;
}

/**
 * A redeemed voucher is stamped with _bu_redeem_user_id at creation
 * (see mycred-woo-order-points). Codes without that stamp are store-wide promos
 * and are not claimable through the app.
 */
function trinh_app_user_owns_coupon(int $user_id, string $code): bool {
    $coupon_id = wc_get_coupon_id_by_code($code);
    if (!$coupon_id) {
        return false;
    }
    $owner = get_post_meta($coupon_id, '_bu_redeem_user_id', true);
    return $owner !== '' && (int) $owner === $user_id;
}

function trinh_app_cancel_my_order(WP_REST_Request $request) {
    $order_id = absint($request->get_param('id'));
    $order    = wc_get_order($order_id);

    if (!$order) {
        return new WP_Error('trinh_order_not_found', 'Order not found.', ['status' => 404]);
    }
    if ((int) $order->get_customer_id() !== get_current_user_id()) {
        return new WP_Error('trinh_order_not_yours', 'That order belongs to another account.', ['status' => 403]);
    }

    // Only orders that have not been paid for or fulfilled may be cancelled by the customer.
    if (!in_array($order->get_status(), ['pending', 'on-hold'], true)) {
        return new WP_Error(
            'trinh_order_not_cancellable',
            sprintf('An order that is %s can no longer be cancelled in the app.', wc_get_order_status_name($order->get_status())),
            ['status' => 409]
        );
    }

    return trinh_app_woo_dispatch('PUT', '/wc/v3/orders/' . $order_id, ['status' => 'cancelled']);
}

/**
 * Timeline of status changes for one of the caller's own orders.
 *
 * The app's order status screen shows a stage per status; without this it has only
 * `date_created` and `date_modified` to work with, so every stage but the current one
 * would be undated.
 */
function trinh_app_get_my_order_history(WP_REST_Request $request) {
    $order_id = absint($request->get_param('id'));
    $order    = wc_get_order($order_id);

    if (!$order) {
        return new WP_Error('trinh_order_not_found', 'Order not found.', ['status' => 404]);
    }
    if ((int) $order->get_customer_id() !== get_current_user_id()) {
        return new WP_Error('trinh_order_not_yours', 'That order belongs to another account.', ['status' => 403]);
    }

    return rest_ensure_response([
        'order_id' => $order_id,
        'status'   => $order->get_status(),
        'history'  => trinh_app_order_status_history($order),
    ]);
}

/**
 * Map WooCommerce's localised status *display names* back to slugs.
 *
 * The transition notes we parse below are written with wc_get_order_status_name(), so the
 * only way back to a slug is through this table. Built at runtime rather than hardcoded
 * so a locale change or a custom status does not silently stop parsing.
 *
 * @return array<string, string> lowercased display name => slug
 */
function trinh_app_status_name_map(): array {
    $map = [];
    foreach (wc_get_order_statuses() as $slug => $label) {
        // wc_get_order_statuses() keys are prefixed ('wc-processing'); order objects are not.
        $map[strtolower($label)] = substr($slug, 0, 3) === 'wc-' ? substr($slug, 3) : $slug;
    }
    return $map;
}

/**
 * Destination slug of a WooCommerce status-transition note, or null if $content is any
 * other kind of note (payment, stock, email, a staff comment).
 *
 * Two wordings exist — class-wc-order.php:464 for a transition between two statuses, and
 * :468 for the first status an order is given.
 */
function trinh_app_parse_transition_note(string $content, array $name_map): ?string {
    $text = trim(wp_strip_all_tags($content));

    if (preg_match('/Order status changed from .+? to (.+?)\.\s*$/i', $text, $m)
        || preg_match('/Order status set to (.+?)\.\s*$/i', $text, $m)) {
        return $name_map[strtolower(trim($m[1]))] ?? null;
    }

    return null;
}

/**
 * Build the status timeline, oldest first.
 *
 * @return array<int, array{status: string, at: string, at_gmt: string}>
 */
function trinh_app_order_status_history(WC_Order $order): array {
    $events = [];

    // 1. Placement. This has to come from date_created, not from a note: WooCommerce
    //    skips the transition note when the previous status was a draft
    //    (class-wc-order.php:462), which is every order created through the website
    //    checkout. 'placed' is synthetic rather than a guess at the initial status —
    //    a bank-transfer order starts on-hold, a card order starts pending.
    $created = $order->get_date_created();
    if ($created) {
        $events[] = ['status' => 'placed', 'ts' => $created->getTimestamp()];
    }

    // 2. Every transition WooCommerce recorded.
    $name_map = trinh_app_status_name_map();
    $notes    = wc_get_order_notes([
        'order_id' => $order->get_id(),
        'orderby'  => 'date_created',
        'order'    => 'ASC',
        'limit'    => 200,
    ]);
    foreach ($notes as $note) {
        $status = trinh_app_parse_transition_note((string) $note->content, $name_map);
        if ($status !== null && $note->date_created) {
            $events[] = ['status' => $status, 'ts' => $note->date_created->getTimestamp()];
        }
    }

    // 3. Guarantee the current status appears. If WooCommerce ever rewords the notes and
    //    every parse above fails, the response still carries placement and where the
    //    order stands now — which is exactly what the app had before this endpoint.
    $current = $order->get_status();
    $has_current = false;
    foreach ($events as $event) {
        if ($event['status'] === $current) {
            $has_current = true;
            break;
        }
    }
    if (!$has_current) {
        $modified = $order->get_date_modified() ?: $created;
        if ($modified) {
            $events[] = ['status' => $current, 'ts' => $modified->getTimestamp()];
        }
    }

    usort($events, function ($a, $b) {
        return $a['ts'] <=> $b['ts'];
    });

    // Collapse runs of the same status, keeping the earliest occurrence. An order bounced
    // processing -> on-hold -> processing legitimately keeps both processing entries.
    $timeline = [];
    $previous = null;
    foreach ($events as $event) {
        if ($event['status'] === $previous) {
            continue;
        }
        $previous   = $event['status'];
        $timeline[] = [
            'status' => $event['status'],
            // Same convention as the WooCommerce REST order payload: `at` in site time,
            // `at_gmt` in UTC. The app formats from at_gmt.
            'at'     => wp_date('Y-m-d\TH:i:s', $event['ts']),
            'at_gmt' => gmdate('Y-m-d\TH:i:s', $event['ts']),
        ];
    }

    return $timeline;
}

function trinh_app_get_my_payment_intent(WP_REST_Request $request) {
    $order_id = absint($request->get_param('id'));
    $order    = wc_get_order($order_id);

    if (!$order) {
        return new WP_Error('trinh_order_not_found', 'Order not found.', ['status' => 404]);
    }
    if ((int) $order->get_customer_id() !== get_current_user_id()) {
        return new WP_Error('trinh_order_not_yours', 'That order belongs to another account.', ['status' => 403]);
    }

    return trinh_app_woo_dispatch('GET', '/wc/v3/orders/' . $order_id . '/stripe/payment-intent');
}

// ─────────────────────────────────────────────────────────────────────────────
// /me/vouchers
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Returns only the caller's redeemed vouchers.
 *
 * The app previously pulled /wc/v3/coupons in full and filtered by an "RW{id}-" code
 * prefix on the device, which handed every store-wide promo code to every customer.
 * Here the query is scoped by the _bu_redeem_user_id stamp instead.
 */
function trinh_app_list_my_vouchers(WP_REST_Request $request) {
    $coupon_ids = get_posts([
        'post_type'      => 'shop_coupon',
        'post_status'    => 'publish',
        'posts_per_page' => 100,
        'fields'         => 'ids',
        'meta_query'     => [[
            'key'   => '_bu_redeem_user_id',
            'value' => get_current_user_id(),
        ]],
    ]);

    if (empty($coupon_ids)) {
        return rest_ensure_response([]);
    }

    // Hand the IDs back to Woo's own coupons controller so the response shape matches
    // /wc/v3/coupons byte for byte — the iOS WCCouponResponse decoder is strict about it.
    return trinh_app_woo_dispatch('GET', '/wc/v3/coupons', [], [
        'include'  => array_map('absint', $coupon_ids),
        'per_page' => 100,
        'orderby'  => 'id',
        'order'    => 'desc',
    ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// /payment-methods
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Enabled standalone gateways only. Sub-methods (Apple/Google Pay express, Stripe Link,
 * SEPA…) are handled inside their parent gateway's sheet, so they are filtered out here
 * rather than on the device.
 */
function trinh_app_list_payment_methods(WP_REST_Request $request) {
    $response = trinh_app_woo_dispatch('GET', '/wc/v3/payment_gateways');
    if (is_wp_error($response)) {
        return $response;
    }

    $gateways = array_values(array_filter((array) $response->get_data(), static function ($gateway) {
        return !empty($gateway['enabled'])
            && !empty($gateway['title'])
            && strpos($gateway['id'], 'woocommerce_payments_') !== 0
            && strpos($gateway['id'], 'stripe_') !== 0;
    }));

    return rest_ensure_response($gateways);
}

// ─────────────────────────────────────────────────────────────────────────────
// /register — public
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Public signup. This exists so the app never needs a write-capable consumer key:
 * account creation is the only write that happens before a JWT is available.
 *
 * Rate-limited per IP because the route is unauthenticated by necessity.
 */
function trinh_app_register_customer(WP_REST_Request $request) {
    $ip_key = 'trinh_reg_' . md5(trinh_app_client_ip());
    $tries  = (int) get_transient($ip_key);
    if ($tries >= 5) {
        return new WP_Error('trinh_too_many_attempts', 'Too many signup attempts. Please try again later.', ['status' => 429]);
    }
    set_transient($ip_key, $tries + 1, 15 * MINUTE_IN_SECONDS);

    $email    = sanitize_email((string) $request->get_param('email'));
    $password = (string) $request->get_param('password');
    $username = sanitize_user((string) $request->get_param('username'), true);

    if (!is_email($email)) {
        return new WP_Error('trinh_invalid_email', 'A valid email address is required.', ['status' => 400]);
    }
    if (strlen($password) < 8) {
        return new WP_Error('trinh_weak_password', 'Password must be at least 8 characters.', ['status' => 400]);
    }
    if (email_exists($email)) {
        return new WP_Error('trinh_email_taken', 'An account with that email already exists.', ['status' => 409]);
    }

    if ($username === '' || username_exists($username)) {
        $username = wc_create_new_customer_username($email);
    }

    $user_id = wc_create_new_customer($email, $username, $password);
    if (is_wp_error($user_id)) {
        return new WP_Error('trinh_registration_failed', $user_id->get_error_message(), ['status' => 400]);
    }

    // The app sends a display name in `username`; split it into first/last for billing.
    $display = sanitize_text_field((string) $request->get_param('name'));
    if ($display === '') {
        $display = sanitize_text_field((string) $request->get_param('username'));
    }
    if ($display !== '') {
        $parts = preg_split('/\s+/', trim($display), 2);
        $customer = new WC_Customer($user_id);
        $customer->set_first_name($parts[0] ?? '');
        $customer->set_last_name($parts[1] ?? '');
        $customer->set_billing_first_name($parts[0] ?? '');
        $customer->set_billing_last_name($parts[1] ?? '');
        $customer->set_billing_email($email);
        $customer->save();
    }

    delete_transient($ip_key);

    return new WP_REST_Response([
        'success' => true,
        'id'      => (int) $user_id,
        'email'   => $email,
    ], 201);
}

function trinh_app_client_ip(): string {
    // Hostinger/LiteSpeed fronts PHP, so prefer the forwarded chain's first hop.
    if (!empty($_SERVER['HTTP_X_FORWARDED_FOR'])) {
        $hops = explode(',', sanitize_text_field(wp_unslash($_SERVER['HTTP_X_FORWARDED_FOR'])));
        $ip   = trim($hops[0]);
        if (filter_var($ip, FILTER_VALIDATE_IP)) {
            return $ip;
        }
    }
    return isset($_SERVER['REMOTE_ADDR'])
        ? sanitize_text_field(wp_unslash($_SERVER['REMOTE_ADDR']))
        : '0.0.0.0';
}

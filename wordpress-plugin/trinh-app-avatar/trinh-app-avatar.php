<?php
/**
 * Plugin Name: Trinh App Avatar
 * Description: Lets the Trinhs Group iOS app manage customer avatars through the authenticated WooCommerce REST API.
 * Version: 1.0.0
 * Requires at least: 6.0
 * Requires PHP: 7.4
 * Author: Trinhs Group
 * License: GPL-2.0-or-later
 */

defined( 'ABSPATH' ) || exit;

const TRINH_APP_AVATAR_META_KEY = '_trinh_app_avatar_url';
const TRINH_APP_AVATAR_ATTACHMENT_META_KEY = '_trinh_app_avatar_attachment_id';

/**
 * Register a WooCommerce-authenticated endpoint.
 *
 * WooCommerce REST API keys authenticate requests in the wc/v3 namespace, so
 * the iOS app can use the same credentials it already uses for customer APIs.
 */
add_action( 'rest_api_init', 'trinh_app_avatar_register_routes' );
function trinh_app_avatar_register_routes() {
	if ( ! class_exists( 'WooCommerce' ) ) {
		return;
	}

	register_rest_route(
		'wc/v3',
		'/customers/(?P<id>\d+)/avatar',
		array(
			array(
				'methods'             => WP_REST_Server::CREATABLE,
				'callback'            => 'trinh_app_avatar_update',
				'permission_callback' => 'trinh_app_avatar_can_edit_customer',
			),
			array(
				'methods'             => WP_REST_Server::DELETABLE,
				'callback'            => 'trinh_app_avatar_delete',
				'permission_callback' => 'trinh_app_avatar_can_edit_customer',
			),
		)
	);

}

/**
 * Require the WooCommerce API key's WordPress user to be able to edit the customer.
 */
function trinh_app_avatar_can_edit_customer( WP_REST_Request $request ) {
	$customer_id = absint( $request['id'] );
	if ( ! $customer_id || ! current_user_can( 'edit_user', $customer_id ) ) {
		return new WP_Error(
			'rest_forbidden',
			__( 'You are not allowed to edit this customer avatar.', 'trinh-app-avatar' ),
			array( 'status' => rest_authorization_required_code() )
		);
	}

	return true;
}

/**
 * Store the uploaded JPEG in the WordPress Media Library and save its URL against the customer.
 */
function trinh_app_avatar_update( WP_REST_Request $request ) {
	$files = $request->get_file_params();
	if ( empty( $files['avatar'] ) || UPLOAD_ERR_OK !== (int) $files['avatar']['error'] ) {
		return new WP_Error(
			'trinh_app_missing_avatar_file',
			__( 'A JPEG avatar file is required.', 'trinh-app-avatar' ),
			array( 'status' => 400 )
		);
	}

	$customer_id = absint( $request['id'] );
	$file        = $files['avatar'];
	$filetype    = wp_check_filetype_and_ext( $file['tmp_name'], $file['name'], array( 'jpg|jpeg' => 'image/jpeg' ) );
	if ( empty( $filetype['type'] ) || 'image/jpeg' !== $filetype['type'] ) {
		return new WP_Error(
			'trinh_app_invalid_avatar_file',
			__( 'Avatar must be a JPEG image.', 'trinh-app-avatar' ),
			array( 'status' => 422 )
		);
	}

	require_once ABSPATH . 'wp-admin/includes/file.php';
	require_once ABSPATH . 'wp-admin/includes/image.php';

	$upload = wp_handle_upload( $file, array( 'test_form' => false, 'mimes' => array( 'jpg|jpeg' => 'image/jpeg' ) ) );
	if ( isset( $upload['error'] ) ) {
		return new WP_Error(
			'trinh_app_avatar_upload_failed',
			$upload['error'],
			array( 'status' => 500 )
		);
	}

	$attachment_id = wp_insert_attachment(
		array(
			'post_mime_type' => $upload['type'],
			'post_title'     => sanitize_file_name( 'customer-' . $customer_id . '-avatar.jpg' ),
			'post_status'    => 'inherit',
		),
		$upload['file']
	);
	if ( is_wp_error( $attachment_id ) ) {
		return $attachment_id;
	}

	wp_update_attachment_metadata( $attachment_id, wp_generate_attachment_metadata( $attachment_id, $upload['file'] ) );
	$old_attachment_id = absint( get_user_meta( $customer_id, TRINH_APP_AVATAR_ATTACHMENT_META_KEY, true ) );
	update_user_meta( $customer_id, TRINH_APP_AVATAR_META_KEY, esc_url_raw( $upload['url'] ) );
	update_user_meta( $customer_id, TRINH_APP_AVATAR_ATTACHMENT_META_KEY, $attachment_id );
	if ( $old_attachment_id && $old_attachment_id !== $attachment_id ) {
		wp_delete_attachment( $old_attachment_id, true );
	}

	return new WP_REST_Response(
		array(
			'user_id'    => $customer_id,
			'avatar_url' => esc_url_raw( $upload['url'] ),
		),
		200
	);
}

/**
 * Remove the custom avatar and its Media Library attachment.
 */
function trinh_app_avatar_delete( WP_REST_Request $request ) {
	$customer_id = absint( $request['id'] );
	$attachment_id = absint( get_user_meta( $customer_id, TRINH_APP_AVATAR_ATTACHMENT_META_KEY, true ) );
	if ( $attachment_id ) {
		wp_delete_attachment( $attachment_id, true );
	}
	delete_user_meta( $customer_id, TRINH_APP_AVATAR_META_KEY );
	delete_user_meta( $customer_id, TRINH_APP_AVATAR_ATTACHMENT_META_KEY );

	return new WP_REST_Response(
		array(
			'user_id'    => $customer_id,
			'avatar_url' => '',
		),
		200
	);
}

/**
 * Replace WooCommerce's read-only Gravatar URL with the app-managed avatar when one exists.
 */
add_filter( 'woocommerce_rest_prepare_customer', 'trinh_app_avatar_add_to_customer_response', 10, 3 );
function trinh_app_avatar_add_to_customer_response( $response, $user, $request ) {
	$avatar_url = get_user_meta( $user->ID, TRINH_APP_AVATAR_META_KEY, true );
	if ( empty( $avatar_url ) ) {
		return $response;
	}

	$data               = $response->get_data();
	$data['avatar_url'] = esc_url_raw( $avatar_url );
	$response->set_data( $data );

	return $response;
}

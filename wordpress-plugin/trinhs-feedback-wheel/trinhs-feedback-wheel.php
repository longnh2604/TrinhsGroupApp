<?php
/**
 * Plugin Name:       Trinh's Feedback Wheel
 * Plugin URI:        https://trinhsgroup.com.au
 * Description:       Post-order 3-question survey with a lucky wheel (rare $50 voucher). Optional non-gating Google review CTA. One play per completed order.
 * Version:           1.0.0
 * Author:            Trinh's Kitchen Group
 * Requires at least: 5.8
 * Requires PHP:      7.4
 * WC requires at least: 6.0
 * WC tested up to:   8.5
 * Text Domain:       trinhs-fw
 */

if ( ! defined( 'ABSPATH' ) ) { exit; }

define( 'TRINHS_FW_VERSION', '1.0.0' );
define( 'TRINHS_FW_FILE', __FILE__ );
define( 'TRINHS_FW_DIR', plugin_dir_path( __FILE__ ) );
define( 'TRINHS_FW_URL', plugin_dir_url( __FILE__ ) );

require_once TRINHS_FW_DIR . 'includes/class-config.php';
require_once TRINHS_FW_DIR . 'includes/class-token.php';
require_once TRINHS_FW_DIR . 'includes/class-wheel.php';
require_once TRINHS_FW_DIR . 'includes/class-store.php';
require_once TRINHS_FW_DIR . 'includes/class-coupon.php';
require_once TRINHS_FW_DIR . 'includes/class-invite.php';
require_once TRINHS_FW_DIR . 'includes/class-page.php';
require_once TRINHS_FW_DIR . 'includes/class-admin.php';
require_once TRINHS_FW_DIR . 'includes/class-mailer.php';

register_activation_hook( __FILE__, function () {
	Trinhs_FW_Store::install();
	Trinhs_FW_Config::secret(); // generate + persist

	// Auto-create the feedback page holding the shortcode, if missing.
	$settings = get_option( Trinhs_FW_Config::OPTION, array() );
	$page_id  = isset( $settings['feedback_page_id'] ) ? (int) $settings['feedback_page_id'] : 0;
	if ( ! $page_id || ! get_post( $page_id ) ) {
		$page_id = wp_insert_post( array(
			'post_title'   => 'Feedback',
			'post_name'    => 'feedback',
			'post_status'  => 'publish',
			'post_type'    => 'page',
			'post_content' => '[trinhs_feedback_wheel]',
		) );
		if ( $page_id && ! is_wp_error( $page_id ) ) {
			$settings['feedback_page_id'] = $page_id;
			update_option( Trinhs_FW_Config::OPTION, array_merge( Trinhs_FW_Config::defaults(), (array) $settings ) );
		}
	}
} );

add_action( 'before_woocommerce_init', function () {
	if ( class_exists( '\Automattic\WooCommerce\Utilities\FeaturesUtil' ) ) {
		\Automattic\WooCommerce\Utilities\FeaturesUtil::declare_compatibility( 'custom_order_tables', TRINHS_FW_FILE, true );
	}
} );

add_action( 'plugins_loaded', function () {
	if ( ! class_exists( 'WooCommerce' ) ) {
		add_action( 'admin_notices', function () {
			if ( current_user_can( 'activate_plugins' ) ) {
				echo '<div class="notice notice-warning"><p><strong>Trinh\'s Feedback Wheel</strong> needs WooCommerce active.</p></div>';
			}
		} );
		return;
	}
	Trinhs_FW_Invite::init();
	Trinhs_FW_Page::init();
	Trinhs_FW_Admin::init();
	Trinhs_FW_Mailer::init();
}, 20 );

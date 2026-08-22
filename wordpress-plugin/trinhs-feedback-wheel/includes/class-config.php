<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }

/**
 * Settings accessor + defaults. Single option 'trinhs_fw_settings' (array),
 * plus a separate auto-generated secret option 'trinhs_fw_secret'.
 */
final class Trinhs_FW_Config {

	const OPTION      = 'trinhs_fw_settings';
	const SECRET_OPT  = 'trinhs_fw_secret';

	public static function defaults() {
		return array(
			'enabled'            => 1,
			'link_validity_days' => 14,
			'coupon_validity'    => 30,
			'coupon_min_spend'   => 30.00,
			'review_google_url'  => 'https://maps.app.goo.gl/LAyeSrRGeyaK6vN1A',
			'review_website_url' => '',
			'feedback_page_id'   => 0,
			'questions'          => array(
				array( 'label' => 'How was the food?',        'type' => 'rating', 'choices' => array() ),
				array( 'label' => 'How was the service?',     'type' => 'rating', 'choices' => array() ),
				array( 'label' => 'Anything we could do better?', 'type' => 'text', 'choices' => array() ),
			),
			'segments'           => array(
				array( 'key' => 'v50',  'label' => '$50 voucher', 'prize_type' => 'coupon', 'discount_type' => 'fixed_cart', 'amount' => 50, 'weight' => 1 ),
				array( 'key' => 'v10',  'label' => '$10 voucher', 'prize_type' => 'coupon', 'discount_type' => 'fixed_cart', 'amount' => 10, 'weight' => 4 ),
				array( 'key' => 'v5',   'label' => '$5 voucher',  'prize_type' => 'coupon', 'discount_type' => 'fixed_cart', 'amount' => 5,  'weight' => 20 ),
				array( 'key' => 'p10',  'label' => '10% off',     'prize_type' => 'coupon', 'discount_type' => 'percent',    'amount' => 10, 'weight' => 20 ),
				array( 'key' => 'none', 'label' => 'Better luck next time', 'prize_type' => 'none', 'discount_type' => '', 'amount' => 0, 'weight' => 355 ),
			),
		);
	}

	public static function get() {
		$saved = get_option( self::OPTION, array() );
		if ( ! is_array( $saved ) ) { $saved = array(); }
		return array_merge( self::defaults(), $saved );
	}

	public static function is_enabled()          { return (bool) self::get()['enabled']; }
	public static function link_validity_days()   { return (int) self::get()['link_validity_days']; }
	public static function coupon_validity_days() { return (int) self::get()['coupon_validity']; }
	public static function coupon_min_spend()     { return (float) self::get()['coupon_min_spend']; }
	public static function review_google_url()    { return (string) self::get()['review_google_url']; }
	public static function review_website_url()   { return (string) self::get()['review_website_url']; }
	public static function feedback_page_id()     { return (int) self::get()['feedback_page_id']; }

	public static function questions() { return (array) self::get()['questions']; }
	public static function segments()  { return (array) self::get()['segments']; }

	public static function secret() {
		$s = get_option( self::SECRET_OPT, '' );
		if ( ! $s ) {
			$s = wp_generate_password( 64, true, true );
			update_option( self::SECRET_OPT, $s, false );
		}
		return $s;
	}

	public static function feedback_url( $token ) {
		$page_id = self::feedback_page_id();
		$base    = $page_id ? get_permalink( $page_id ) : home_url( '/feedback/' );
		return add_query_arg( 't', rawurlencode( $token ), $base );
	}
}

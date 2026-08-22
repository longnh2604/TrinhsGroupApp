<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }

final class Trinhs_FW_Coupon {

	const CODE_PREFIX = 'TFW';

	public static function mint( array $segment, string $email, int $order_id ): ?string {
		if ( ( $segment['prize_type'] ?? 'none' ) !== 'coupon' ) {
			return null;
		}
		$code = self::generate_code( $segment['key'] );
		if ( ! $code ) { return null; }

		$coupon = new WC_Coupon();
		$coupon->set_code( $code );
		$coupon->set_discount_type( (string) $segment['discount_type'] ); // 'fixed_cart' | 'percent'
		$coupon->set_amount( (float) $segment['amount'] );
		$coupon->set_individual_use( true );
		$coupon->set_usage_limit( 1 );
		$coupon->set_usage_limit_per_user( 1 );
		$coupon->set_email_restrictions( array( strtolower( $email ) ) );
		$coupon->set_date_expires( self::expiry_ts() );
		$coupon->set_minimum_amount( (string) Trinhs_FW_Config::coupon_min_spend() );
		$coupon->set_description( sprintf( 'Feedback wheel prize (%s) from order #%d.', $segment['key'], $order_id ) );

		$coupon_id = $coupon->save();
		if ( ! $coupon_id ) { return null; }

		update_post_meta( $coupon_id, '_trinhs_fw_source_order_id', $order_id );
		update_post_meta( $coupon_id, '_trinhs_fw_prize_key', $segment['key'] );
		return $code;
	}

	private static function generate_code( $prize_key ) {
		$attempts = 0;
		do {
			$suffix = strtoupper( wp_generate_password( 5, false, false ) );
			$code   = sprintf( '%s-%s-%s', self::CODE_PREFIX, strtoupper( $prize_key ), $suffix );
			++$attempts;
			if ( ! wc_get_coupon_id_by_code( $code ) ) { return $code; }
		} while ( $attempts < 8 );
		return null;
	}

	private static function expiry_ts() {
		$days = Trinhs_FW_Config::coupon_validity_days();
		$tz   = function_exists( 'wp_timezone' ) ? wp_timezone() : new DateTimeZone( 'UTC' );
		$now  = new DateTime( 'now', $tz );
		$now->modify( '+' . $days . ' days' );
		return $now->getTimestamp();
	}
}

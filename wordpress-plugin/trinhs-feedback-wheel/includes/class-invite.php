<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }

final class Trinhs_FW_Invite {
	const META_SENT = '_trinhs_fw_invited';

	public static function init() {
		add_action( 'woocommerce_order_status_completed', array( __CLASS__, 'maybe_send' ), 20, 2 );
	}

	public static function maybe_send( $order_id, $order = null ) {
		try {
			if ( ! Trinhs_FW_Config::is_enabled() ) { return; }
			if ( ! $order instanceof WC_Order ) { $order = wc_get_order( $order_id ); }
			if ( ! $order instanceof WC_Order ) { return; }
			if ( $order->get_meta( self::META_SENT ) ) { return; } // idempotent
			$email = $order->get_billing_email();
			if ( empty( $email ) ) { return; }

			$token = Trinhs_FW_Token::sign(
				array( 'order_id' => (int) $order_id, 'email' => $email, 'iat' => time() ),
				Trinhs_FW_Config::secret()
			);
			$url = Trinhs_FW_Config::feedback_url( $token );

			$order->update_meta_data( self::META_SENT, current_time( 'mysql' ) );
			$order->save();

			do_action( 'trinhs_fw_invited', $order, $url );
		} catch ( \Throwable $e ) {
			error_log( '[trinhs-fw] Invite failed for order ' . $order_id . ': ' . $e->getMessage() );
		}
	}
}

<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }

final class Trinhs_FW_Mailer {
	public static function init() {
		add_filter( 'woocommerce_email_classes', array( __CLASS__, 'register' ) );
		add_action( 'trinhs_fw_invited', array( __CLASS__, 'send_invite' ), 10, 2 );
		add_action( 'trinhs_fw_won',     array( __CLASS__, 'send_prize' ),  10, 5 );
	}
	public static function register( $emails ) {
		if ( ! class_exists( 'WC_Email' ) ) { return $emails; }
		require_once TRINHS_FW_DIR . 'includes/class-emails.php';
		if ( class_exists( 'WC_Email_Trinhs_FW_Invite' ) ) { $emails['WC_Email_Trinhs_FW_Invite'] = new WC_Email_Trinhs_FW_Invite(); }
		if ( class_exists( 'WC_Email_Trinhs_FW_Prize' ) )  { $emails['WC_Email_Trinhs_FW_Prize']  = new WC_Email_Trinhs_FW_Prize(); }
		return $emails;
	}
	private static function email( $class ) {
		if ( ! function_exists( 'WC' ) ) { return null; }
		WC()->mailer();
		$emails = WC()->mailer()->get_emails();
		return $emails[ $class ] ?? null;
	}
	public static function send_invite( $order, $url ) {
		$e = self::email( 'WC_Email_Trinhs_FW_Invite' );
		if ( $e ) { $e->trigger( $order, $url ); }
	}
	public static function send_prize( $order, $code, $discount_type, $amount, $expires_ts ) {
		$e = self::email( 'WC_Email_Trinhs_FW_Prize' );
		if ( $e ) { $e->trigger( $order, $code, $discount_type, $amount, $expires_ts ); }
	}
}

<?php
/**
 * Plugin Name:       Trinh's Loyalty Vouchers
 * Plugin URI:        https://trinhsgroup.com.au
 * Description:       Tiered voucher rewards for completed WooCommerce orders ($140+ → $10, $80+ → $5). 7-day expiry. $30 min-spend to redeem. Auto-restore on refund, auto-revoke if the earning order is refunded unused.
 * Version:           1.0.0
 * Author:            Trinh's Kitchen Group
 * Requires at least: 5.8
 * Requires PHP:      7.4
 * WC requires at least: 6.0
 * WC tested up to:   8.5
 * Text Domain:       trinhs
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'TRINHS_VOUCHER_VERSION', '1.0.0' );
define( 'TRINHS_VOUCHER_FILE', __FILE__ );
define( 'TRINHS_VOUCHER_DIR', plugin_dir_path( __FILE__ ) );

/**
 * Tier configuration. Edit these constants to retune the program.
 */
final class Trinhs_Voucher_Config {
	const TIER_TOP_THRESHOLD    = 140.00; // AUD — order total ≥ this earns TIER_TOP_VALUE.
	const TIER_TOP_VALUE        = 10.00;
	const TIER_MID_THRESHOLD    = 80.00;  // AUD — order total ≥ this earns TIER_MID_VALUE.
	const TIER_MID_VALUE        = 5.00;
	const VOUCHER_VALIDITY_DAYS = 7;
	const REDEMPTION_MIN_SPEND  = 30.00;  // AUD — cart subtotal needed to redeem.
	const CODE_PREFIX           = 'TRINHS';

	/**
	 * @param  float $order_total Amount the customer paid.
	 * @return array{0: float, 1: string}|null
	 */
	public static function tier_for( $order_total ) {
		$total = (float) $order_total;
		if ( $total >= self::TIER_TOP_THRESHOLD ) {
			return array( self::TIER_TOP_VALUE, 'tier_10' );
		}
		if ( $total >= self::TIER_MID_THRESHOLD ) {
			return array( self::TIER_MID_VALUE, 'tier_5' );
		}
		return null;
	}
}

/**
 * Issuer — creates a coupon when a qualifying order completes.
 */
final class Trinhs_Voucher_Issuer {
	const META_ISSUED_CODE = '_trinhs_voucher_issued_code';

	public static function init() {
		add_action( 'woocommerce_order_status_completed', array( __CLASS__, 'maybe_issue' ), 20, 2 );
	}

	public static function maybe_issue( $order_id, $order = null ) {
		try {
			if ( ! $order instanceof WC_Order ) {
				$order = wc_get_order( $order_id );
			}
			if ( ! $order instanceof WC_Order ) {
				return;
			}
			if ( $order->get_meta( self::META_ISSUED_CODE ) ) {
				return; // idempotency
			}

			$tier = Trinhs_Voucher_Config::tier_for( $order->get_total() );
			if ( null === $tier ) {
				return;
			}
			list( $value, $tier_key ) = $tier;

			$customer_email = $order->get_billing_email();
			if ( empty( $customer_email ) ) {
				return;
			}

			$code = self::generate_code( (int) $value );
			if ( ! $code ) {
				return;
			}

			$expires_ts = self::compute_expiry_ts();
			$coupon_id  = self::create_coupon( $code, $value, $customer_email, $expires_ts, $order_id, $tier_key );
			if ( ! $coupon_id ) {
				return;
			}

			$order->update_meta_data( self::META_ISSUED_CODE, $code );
			$order->save();

			do_action( 'trinhs_voucher_issued', $coupon_id, $code, $value, $expires_ts, $order );
		} catch ( \Throwable $e ) {
			error_log( '[trinhs-vouchers] Issuer failed for order ' . $order_id . ': ' . $e->getMessage() );
		}
	}

	private static function generate_code( $value ) {
		$attempts = 0;
		do {
			$suffix = strtoupper( wp_generate_password( 4, false, false ) );
			$code   = sprintf( '%s%d-%s', Trinhs_Voucher_Config::CODE_PREFIX, $value, $suffix );
			++$attempts;
			if ( ! wc_get_coupon_id_by_code( $code ) ) {
				return $code;
			}
		} while ( $attempts < 8 );
		return null;
	}

	private static function compute_expiry_ts() {
		$days = (int) Trinhs_Voucher_Config::VOUCHER_VALIDITY_DAYS;
		$tz   = function_exists( 'wp_timezone' ) ? wp_timezone() : new DateTimeZone( 'UTC' );
		$now  = new DateTime( 'now', $tz );
		$now->modify( '+' . $days . ' days' );
		return $now->getTimestamp();
	}

	private static function create_coupon( $code, $value, $customer_email, $expires_ts, $source_order_id, $tier_key ) {
		$coupon = new WC_Coupon();
		$coupon->set_code( $code );
		$coupon->set_discount_type( 'fixed_cart' );
		$coupon->set_amount( $value );
		$coupon->set_individual_use( true );
		$coupon->set_usage_limit( 1 );
		$coupon->set_usage_limit_per_user( 1 );
		$coupon->set_email_restrictions( array( strtolower( $customer_email ) ) );
		$coupon->set_date_expires( $expires_ts );
		$coupon->set_minimum_amount( (string) Trinhs_Voucher_Config::REDEMPTION_MIN_SPEND );
		$coupon->set_description(
			sprintf(
				'Auto-issued loyalty voucher from order #%d (%s).',
				(int) $source_order_id,
				$tier_key
			)
		);

		$coupon_id = $coupon->save();
		if ( ! $coupon_id ) {
			return 0;
		}

		update_post_meta( $coupon_id, '_trinhs_source_order_id', $source_order_id );
		update_post_meta( $coupon_id, '_trinhs_voucher_tier', $tier_key );
		update_post_meta( $coupon_id, '_trinhs_restoration_count', 0 );

		return $coupon_id;
	}
}

/**
 * Min-spend notice — make the message customer-friendly when cart < $30.
 */
final class Trinhs_Voucher_Min_Spend_Notice {
	public static function init() {
		add_filter( 'woocommerce_coupon_error', array( __CLASS__, 'customise_message' ), 10, 3 );
	}

	public static function customise_message( $err, $err_code, $coupon ) {
		if ( ! ( $coupon instanceof WC_Coupon ) ) {
			return $err;
		}
		if ( (int) WC_Coupon::E_WC_COUPON_MIN_SPEND_LIMIT_NOT_MET !== (int) $err_code ) {
			return $err;
		}
		if ( stripos( $coupon->get_code(), Trinhs_Voucher_Config::CODE_PREFIX ) !== 0 ) {
			return $err;
		}

		$cart = function_exists( 'WC' ) ? WC()->cart : null;
		$min  = (float) $coupon->get_minimum_amount();
		$have = ( $cart && method_exists( $cart, 'get_displayed_subtotal' ) ) ? (float) $cart->get_displayed_subtotal() : 0.0;
		$gap  = max( 0, $min - $have );

		return sprintf(
			/* translators: 1: voucher code, 2: gap amount, 3: required minimum */
			__( 'Your Trinh\'s voucher %1$s needs a minimum spend of %3$s. Add %2$s more to your cart to unlock it.', 'trinhs' ),
			'<strong>' . esc_html( $coupon->get_code() ) . '</strong>',
			wc_price( $gap ),
			wc_price( $min )
		);
	}
}

/**
 * Restorer — when an order that USED a Trinh's voucher is refunded/failed/cancelled,
 * reset the coupon (keep original expiry) and email the customer.
 */
final class Trinhs_Voucher_Restorer {
	public static function init() {
		add_action( 'woocommerce_order_status_refunded',  array( __CLASS__, 'handle' ), 20, 2 );
		add_action( 'woocommerce_order_status_failed',    array( __CLASS__, 'handle' ), 20, 2 );
		add_action( 'woocommerce_order_status_cancelled', array( __CLASS__, 'handle' ), 20, 2 );
	}

	public static function handle( $order_id, $order = null ) {
		try {
			if ( ! $order instanceof WC_Order ) {
				$order = wc_get_order( $order_id );
			}
			if ( ! $order instanceof WC_Order ) {
				return;
			}

			$used_codes = $order->get_coupon_codes();
			if ( empty( $used_codes ) ) {
				return;
			}

			foreach ( $used_codes as $code ) {
				if ( stripos( $code, Trinhs_Voucher_Config::CODE_PREFIX ) !== 0 ) {
					continue;
				}
				$coupon_id = wc_get_coupon_id_by_code( $code );
				if ( ! $coupon_id ) {
					continue;
				}
				$coupon = new WC_Coupon( $coupon_id );

				$restoration_count = (int) get_post_meta( $coupon_id, '_trinhs_restoration_count', true );
				update_post_meta( $coupon_id, '_trinhs_restoration_count', $restoration_count + 1 );

				$coupon->set_usage_count( 0 );
				$coupon->save();

				$expiry    = $coupon->get_date_expires();
				$expires_ts = $expiry ? $expiry->getTimestamp() : 0;

				do_action( 'trinhs_voucher_restored', $coupon, $order, $code, $expires_ts );
			}
		} catch ( \Throwable $e ) {
			error_log( '[trinhs-vouchers] Restorer failed for order ' . $order_id . ': ' . $e->getMessage() );
		}
	}
}

/**
 * Revoker — when the order that EARNED a voucher is refunded/failed/cancelled and
 * the voucher hasn't been used yet, expire it.
 */
final class Trinhs_Voucher_Revoker {
	public static function init() {
		add_action( 'woocommerce_order_status_refunded',  array( __CLASS__, 'handle' ), 25, 2 );
		add_action( 'woocommerce_order_status_failed',    array( __CLASS__, 'handle' ), 25, 2 );
		add_action( 'woocommerce_order_status_cancelled', array( __CLASS__, 'handle' ), 25, 2 );
	}

	public static function handle( $order_id, $order = null ) {
		try {
			if ( ! $order instanceof WC_Order ) {
				$order = wc_get_order( $order_id );
			}
			if ( ! $order instanceof WC_Order ) {
				return;
			}

			$issued_code = $order->get_meta( Trinhs_Voucher_Issuer::META_ISSUED_CODE );
			if ( empty( $issued_code ) ) {
				return;
			}

			$coupon_id = wc_get_coupon_id_by_code( $issued_code );
			if ( ! $coupon_id ) {
				return;
			}
			$coupon = new WC_Coupon( $coupon_id );

			if ( (int) $coupon->get_usage_count() > 0 ) {
				return; // already redeemed — leave alone
			}
			if ( get_post_meta( $coupon_id, '_trinhs_revoked', true ) ) {
				return; // already revoked — don't email twice
			}

			$coupon->set_date_expires( time() - 1 );
			$coupon->save();
			update_post_meta( $coupon_id, '_trinhs_revoked', 1 );

			do_action( 'trinhs_voucher_revoked', $coupon, $order, $issued_code );
		} catch ( \Throwable $e ) {
			error_log( '[trinhs-vouchers] Revoker failed for order ' . $order_id . ': ' . $e->getMessage() );
		}
	}
}

/**
 * Mailer dispatcher — wires the three transactional emails.
 * The email classes themselves live in includes/class-emails.php and are loaded
 * lazily by the woocommerce_email_classes filter, AFTER WC_Email exists.
 */
final class Trinhs_Voucher_Mailer {
	public static function init() {
		add_filter( 'woocommerce_email_classes', array( __CLASS__, 'register' ) );
		add_action( 'trinhs_voucher_issued',   array( __CLASS__, 'send_issued' ),   10, 5 );
		add_action( 'trinhs_voucher_restored', array( __CLASS__, 'send_restored' ), 10, 4 );
		add_action( 'trinhs_voucher_revoked',  array( __CLASS__, 'send_revoked' ),  10, 3 );
	}

	public static function register( $emails ) {
		if ( ! class_exists( 'WC_Email' ) ) {
			return $emails;
		}
		require_once TRINHS_VOUCHER_DIR . 'includes/class-emails.php';

		if ( class_exists( 'WC_Email_Trinhs_Voucher_Issued' ) ) {
			$emails['WC_Email_Trinhs_Voucher_Issued'] = new WC_Email_Trinhs_Voucher_Issued();
		}
		if ( class_exists( 'WC_Email_Trinhs_Voucher_Restored' ) ) {
			$emails['WC_Email_Trinhs_Voucher_Restored'] = new WC_Email_Trinhs_Voucher_Restored();
		}
		if ( class_exists( 'WC_Email_Trinhs_Voucher_Revoked' ) ) {
			$emails['WC_Email_Trinhs_Voucher_Revoked'] = new WC_Email_Trinhs_Voucher_Revoked();
		}
		return $emails;
	}

	public static function send_issued( $coupon_id, $code, $value, $expires_ts, $order ) {
		$email = self::get_email( 'WC_Email_Trinhs_Voucher_Issued' );
		if ( $email ) {
			$email->trigger( $order, $code, $value, $expires_ts );
		}
	}

	public static function send_restored( $coupon, $order, $code, $expires_ts ) {
		$email = self::get_email( 'WC_Email_Trinhs_Voucher_Restored' );
		if ( $email ) {
			$value = (float) $coupon->get_amount();
			$email->trigger( $order, $code, $value, $expires_ts );
		}
	}

	public static function send_revoked( $coupon, $order, $code ) {
		$email = self::get_email( 'WC_Email_Trinhs_Voucher_Revoked' );
		if ( $email ) {
			$value = (float) $coupon->get_amount();
			$email->trigger( $order, $code, $value, 0 );
		}
	}

	private static function get_email( $class_name ) {
		if ( ! function_exists( 'WC' ) ) {
			return null;
		}
		WC()->mailer(); // initialise
		$emails = WC()->mailer()->get_emails();
		return isset( $emails[ $class_name ] ) ? $emails[ $class_name ] : null;
	}
}

// ─── Bootstrap ─────────────────────────────────────────────────────────────

add_action(
	'plugins_loaded',
	function () {
		if ( ! class_exists( 'WooCommerce' ) ) {
			add_action(
				'admin_notices',
				function () {
					if ( current_user_can( 'activate_plugins' ) ) {
						echo '<div class="notice notice-warning"><p><strong>Trinh\'s Loyalty Vouchers</strong> needs WooCommerce to be active. The plugin is loaded but doing nothing right now.</p></div>';
					}
				}
			);
			return;
		}

		Trinhs_Voucher_Issuer::init();
		Trinhs_Voucher_Mailer::init();
		Trinhs_Voucher_Min_Spend_Notice::init();
		Trinhs_Voucher_Restorer::init();
		Trinhs_Voucher_Revoker::init();
	},
	20
);

// Declare HPOS compatibility (WooCommerce 7.1+ High-Performance Order Storage).
add_action(
	'before_woocommerce_init',
	function () {
		if ( class_exists( '\Automattic\WooCommerce\Utilities\FeaturesUtil' ) ) {
			\Automattic\WooCommerce\Utilities\FeaturesUtil::declare_compatibility( 'custom_order_tables', TRINHS_VOUCHER_FILE, true );
		}
	}
);

<?php
/**
 * Email classes for Trinh's Loyalty Vouchers.
 *
 * Loaded lazily via the woocommerce_email_classes filter, AFTER WC_Email exists.
 *
 * @package Trinhs_Loyalty_Vouchers
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! class_exists( 'WC_Email' ) ) {
	return;
}

if ( ! class_exists( 'WC_Email_Trinhs_Voucher_Base' ) ) {

	/**
	 * Shared base — three concrete emails inherit from this.
	 */
	abstract class WC_Email_Trinhs_Voucher_Base extends WC_Email {

		public function __construct() {
			$this->customer_email = true;
			$this->template_base  = trailingslashit( get_stylesheet_directory() ) . 'woocommerce/';
			$this->placeholders   = array(
				'{voucher_code}'        => '',
				'{voucher_value}'       => '',
				'{voucher_expiry}'      => '',
				'{voucher_min_spend}'   => '',
				'{customer_first_name}' => '',
			);
			parent::__construct();
		}

		/**
		 * Fired by Trinhs_Voucher_Mailer.
		 *
		 * @param WC_Order $order
		 * @param string   $code
		 * @param float    $value
		 * @param int      $expires_ts
		 */
		public function trigger( $order, $code, $value, $expires_ts ) {
			if ( ! ( $order instanceof WC_Order ) ) {
				return;
			}

			$this->object    = $order;
			$this->recipient = $order->get_billing_email();

			$currency = $order->get_currency();
			$expiry_s = $expires_ts ? wp_date( get_option( 'date_format' ), (int) $expires_ts ) : '';

			$this->placeholders['{voucher_code}']        = $code;
			$this->placeholders['{voucher_value}']       = wc_price( $value, array( 'currency' => $currency ) );
			$this->placeholders['{voucher_expiry}']      = $expiry_s;
			$this->placeholders['{voucher_min_spend}']   = wc_price( Trinhs_Voucher_Config::REDEMPTION_MIN_SPEND, array( 'currency' => $currency ) );
			$this->placeholders['{customer_first_name}'] = $order->get_billing_first_name();

			if ( $this->is_enabled() && $this->get_recipient() ) {
				$this->send(
					$this->get_recipient(),
					$this->get_subject(),
					$this->get_content(),
					$this->get_headers(),
					$this->get_attachments()
				);
			}
		}

		public function get_content_html() {
			return wc_get_template_html(
				$this->template_html,
				$this->template_args(),
				'',
				$this->template_base
			);
		}

		public function get_content_plain() {
			return wc_get_template_html(
				$this->template_plain,
				$this->template_args(),
				'',
				$this->template_base
			);
		}

		protected function template_args() {
			return array(
				'order'               => $this->object,
				'email_heading'       => $this->get_heading(),
				'additional_content'  => '',
				'sent_to_admin'       => false,
				'plain_text'          => false,
				'email'               => $this,
				'voucher_code'        => $this->placeholders['{voucher_code}'],
				'voucher_value'       => $this->placeholders['{voucher_value}'],
				'voucher_expiry'      => $this->placeholders['{voucher_expiry}'],
				'voucher_min_spend'   => $this->placeholders['{voucher_min_spend}'],
				'customer_first_name' => $this->placeholders['{customer_first_name}'],
			);
		}
	}

	/**
	 * Voucher Issued.
	 */
	class WC_Email_Trinhs_Voucher_Issued extends WC_Email_Trinhs_Voucher_Base {
		public function __construct() {
			$this->id             = 'trinhs_voucher_issued';
			$this->title          = "Trinh's: Voucher Issued";
			$this->description    = 'Sent to the customer when their completed order earns a loyalty voucher.';
			$this->template_html  = 'emails/customer-voucher-issued.php';
			$this->template_plain = 'emails/plain/customer-voucher-issued.php';
			parent::__construct();
		}
		public function get_default_subject() {
			return '[{site_title}] You have earned a {voucher_value} voucher';
		}
		public function get_default_heading() {
			return 'A little thank-you from Trinh\'s';
		}
	}

	/**
	 * Voucher Restored.
	 */
	class WC_Email_Trinhs_Voucher_Restored extends WC_Email_Trinhs_Voucher_Base {
		public function __construct() {
			$this->id             = 'trinhs_voucher_restored';
			$this->title          = "Trinh's: Voucher Restored";
			$this->description    = 'Sent when a voucher is restored after the order it was used on is refunded/failed.';
			$this->template_html  = 'emails/customer-voucher-restored.php';
			$this->template_plain = 'emails/plain/customer-voucher-restored.php';
			parent::__construct();
		}
		public function get_default_subject() {
			return '[{site_title}] Your voucher {voucher_code} has been restored';
		}
		public function get_default_heading() {
			return 'Your voucher is back';
		}
	}

	/**
	 * Voucher Revoked.
	 */
	class WC_Email_Trinhs_Voucher_Revoked extends WC_Email_Trinhs_Voucher_Base {
		public function __construct() {
			$this->id             = 'trinhs_voucher_revoked';
			$this->title          = "Trinh's: Voucher Revoked";
			$this->description    = 'Sent when an order that earned a voucher is refunded before the voucher was used.';
			$this->template_html  = 'emails/customer-voucher-revoked.php';
			$this->template_plain = 'emails/plain/customer-voucher-revoked.php';
			parent::__construct();
		}
		public function get_default_subject() {
			return '[{site_title}] Voucher {voucher_code} revoked';
		}
		public function get_default_heading() {
			return 'Voucher revoked';
		}
	}
}

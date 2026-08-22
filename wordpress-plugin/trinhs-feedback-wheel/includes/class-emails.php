<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
if ( ! class_exists( 'WC_Email' ) ) { return; }

if ( ! class_exists( 'WC_Email_Trinhs_FW_Invite' ) ) {

	class WC_Email_Trinhs_FW_Invite extends WC_Email {
		public function __construct() {
			$this->id             = 'trinhs_fw_invite';
			$this->title          = "Trinh's: Feedback Invite";
			$this->description    = 'Invites the customer to the feedback survey + lucky wheel after order completion.';
			$this->customer_email = true;
			parent::__construct();
		}
		public function get_default_subject() { return '[{site_title}] Tell us how we did — spin to win up to $50'; }
		public function get_default_heading() { return 'Thanks for your order!'; }

		public function trigger( $order, $url ) {
			if ( ! ( $order instanceof WC_Order ) ) { return; }
			$this->object    = $order;
			$this->recipient = $order->get_billing_email();
			$this->url       = $url;
			$this->first     = $order->get_billing_first_name();
			if ( $this->is_enabled() && $this->get_recipient() ) {
				$this->send( $this->get_recipient(), $this->get_subject(), $this->get_content(), $this->get_headers(), $this->get_attachments() );
			}
		}

		public function get_content_html() {
			return $this->wrap( sprintf(
				'<p>Hi %s,</p><p>Thanks for ordering with Trinh\'s! Please answer 3 quick questions and spin our lucky wheel — you could win up to a <strong>$50 voucher</strong>.</p><p><a href="%s" style="display:inline-block;padding:12px 20px;background:#b8232f;color:#fff;text-decoration:none;border-radius:6px;">Start survey &amp; spin</a></p><p style="font-size:12px;color:#777;">This link is unique to your order.</p>',
				esc_html( $this->first ), esc_url( $this->url )
			) );
		}
		public function get_content_plain() {
			return sprintf( "Hi %s,\n\nThanks for ordering with Trinh's! Answer 3 quick questions and spin our lucky wheel to win up to a \$50 voucher:\n%s\n", $this->first, $this->url );
		}
		private function wrap( $body ) {
			ob_start();
			wc_get_template( 'emails/email-header.php', array( 'email_heading' => $this->get_heading(), 'email' => $this ) );
			echo $body;
			wc_get_template( 'emails/email-footer.php', array( 'email' => $this ) );
			return ob_get_clean();
		}
	}

	class WC_Email_Trinhs_FW_Prize extends WC_Email {
		public function __construct() {
			$this->id             = 'trinhs_fw_prize';
			$this->title          = "Trinh's: Wheel Prize";
			$this->description    = 'Sent when a customer wins a coupon on the lucky wheel.';
			$this->customer_email = true;
			parent::__construct();
		}
		public function get_default_subject() { return '[{site_title}] You won! Here is your voucher'; }
		public function get_default_heading() { return 'Congratulations — you won!'; }

		public function trigger( $order, $code, $discount_type, $amount, $expires_ts ) {
			if ( ! ( $order instanceof WC_Order ) ) { return; }
			$this->object    = $order;
			$this->recipient = $order->get_billing_email();
			$currency        = $order->get_currency();
			$this->prize     = ( 'percent' === $discount_type )
				? rtrim( rtrim( number_format( (float) $amount, 2 ), '0' ), '.' ) . '% off'
				: wc_price( $amount, array( 'currency' => $currency ) );
			$this->code      = $code;
			$this->expiry    = $expires_ts ? wp_date( get_option( 'date_format' ), (int) $expires_ts ) : '';
			$this->min_spend = wc_price( Trinhs_FW_Config::coupon_min_spend(), array( 'currency' => $currency ) );
			$this->first     = $order->get_billing_first_name();
			if ( $this->is_enabled() && $this->get_recipient() ) {
				$this->send( $this->get_recipient(), $this->get_subject(), $this->get_content(), $this->get_headers(), $this->get_attachments() );
			}
		}

		public function get_content_html() {
			ob_start();
			wc_get_template( 'emails/email-header.php', array( 'email_heading' => $this->get_heading(), 'email' => $this ) );
			printf(
				'<p>Hi %s,</p><p>You won <strong>%s</strong> on our lucky wheel! Use this code at checkout:</p><p style="font-size:20px;font-weight:bold;letter-spacing:1px;">%s</p><p>Minimum spend %s. Expires %s.</p>',
				esc_html( $this->first ), wp_kses_post( $this->prize ), esc_html( $this->code ), wp_kses_post( $this->min_spend ), esc_html( $this->expiry )
			);
			wc_get_template( 'emails/email-footer.php', array( 'email' => $this ) );
			return ob_get_clean();
		}
		public function get_content_plain() {
			return sprintf( "Hi %s,\n\nYou won %s on our lucky wheel!\nCode: %s\nMinimum spend %s. Expires %s.\n",
				$this->first, wp_strip_all_tags( $this->prize ), $this->code, wp_strip_all_tags( $this->min_spend ), $this->expiry );
		}
	}
}

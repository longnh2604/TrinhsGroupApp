<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }

final class Trinhs_FW_Page {

	public static function init() {
		add_shortcode( 'trinhs_feedback_wheel', array( __CLASS__, 'render' ) );
		add_action( 'wp_ajax_trinhs_fw_submit',        array( __CLASS__, 'handle_submit' ) );
		add_action( 'wp_ajax_nopriv_trinhs_fw_submit', array( __CLASS__, 'handle_submit' ) );
	}

	/** Validate token + expiry; return payload or null. */
	private static function validate_token( $token ) {
		if ( ! $token ) { return null; }
		$payload = Trinhs_FW_Token::verify( $token, Trinhs_FW_Config::secret() );
		if ( ! is_array( $payload ) || empty( $payload['order_id'] ) ) { return null; }
		$max_age = Trinhs_FW_Config::link_validity_days() * DAY_IN_SECONDS;
		if ( ( time() - (int) ( $payload['iat'] ?? 0 ) ) > $max_age ) { return null; }
		return $payload;
	}

	public static function render() {
		if ( ! Trinhs_FW_Config::is_enabled() ) {
			return '<p>' . esc_html__( 'The feedback survey is currently unavailable.', 'trinhs-fw' ) . '</p>';
		}
		$token   = isset( $_GET['t'] ) ? sanitize_text_field( wp_unslash( $_GET['t'] ) ) : '';
		$payload = self::validate_token( $token );
		if ( ! $payload ) {
			return '<p>' . esc_html__( 'This link is no longer valid or has expired.', 'trinhs-fw' ) . '</p>';
		}

		$existing = Trinhs_FW_Store::get( (int) $payload['order_id'] );
		if ( $existing && ! empty( $existing['prize_key'] ) ) {
			return self::already_played_html( $existing );
		}

		wp_enqueue_style( 'trinhs-fw', TRINHS_FW_URL . 'assets/wheel.css', array(), TRINHS_FW_VERSION );
		wp_enqueue_script( 'trinhs-fw', TRINHS_FW_URL . 'assets/wheel.js', array(), TRINHS_FW_VERSION, true );
		wp_localize_script( 'trinhs-fw', 'TRINHS_FW', array(
			'ajax_url' => admin_url( 'admin-ajax.php' ),
			'nonce'    => wp_create_nonce( 'trinhs_fw' ),
			'token'    => $token,
			'segments' => array_map( function ( $s ) {
				return array( 'key' => $s['key'], 'label' => $s['label'] );
			}, Trinhs_FW_Config::segments() ),
		) );

		ob_start();
		$questions   = Trinhs_FW_Config::questions();
		$google_url  = Trinhs_FW_Config::review_google_url();
		$website_url = Trinhs_FW_Config::review_website_url();
		include TRINHS_FW_DIR . 'templates/survey-page.php';
		return ob_get_clean();
	}

	private static function already_played_html( $row ) {
		if ( ! empty( $row['coupon_code'] ) ) {
			return '<div class="trinhs-fw-done"><p>' . esc_html__( 'You have already played and won:', 'trinhs-fw' ) .
				' <strong>' . esc_html( $row['coupon_code'] ) . '</strong></p></div>';
		}
		return '<div class="trinhs-fw-done"><p>' . esc_html__( 'You have already completed this survey. Thank you!', 'trinhs-fw' ) . '</p></div>';
	}

	public static function handle_submit() {
		check_ajax_referer( 'trinhs_fw', 'nonce' );

		$token   = isset( $_POST['token'] ) ? sanitize_text_field( wp_unslash( $_POST['token'] ) ) : '';
		$payload = self::validate_token( $token );
		if ( ! $payload || ! Trinhs_FW_Config::is_enabled() ) {
			wp_send_json_error( array( 'message' => __( 'This link is no longer valid.', 'trinhs-fw' ) ) );
		}
		$order_id = (int) $payload['order_id'];
		$email    = (string) $payload['email'];

		$answers = array();
		for ( $i = 1; $i <= 3; $i++ ) {
			$answers[] = isset( $_POST[ 'q' . $i ] ) ? sanitize_textarea_field( wp_unslash( $_POST[ 'q' . $i ] ) ) : '';
		}

		// If already resolved (replay), return the stored result.
		$existing = Trinhs_FW_Store::get( $order_id );
		if ( $existing && ! empty( $existing['prize_key'] ) ) {
			wp_send_json_success( self::result_payload( $existing['prize_key'], $existing['coupon_code'] ) );
		}

		// Claim BEFORE minting so a race can never create two coupons.
		if ( ! Trinhs_FW_Store::claim( $order_id, $email, $answers ) ) {
			$existing = Trinhs_FW_Store::get( $order_id );
			if ( $existing && ! empty( $existing['prize_key'] ) ) {
				wp_send_json_success( self::result_payload( $existing['prize_key'], $existing['coupon_code'] ) );
			}
			wp_send_json_error( array( 'message' => __( 'You have already played.', 'trinhs-fw' ) ) );
		}

		$segments = Trinhs_FW_Config::segments();
		$total    = Trinhs_FW_Wheel::total_weight( $segments );
		$roll     = random_int( 0, max( 0, $total - 1 ) );
		$key      = Trinhs_FW_Wheel::pick( $segments, $roll );

		$segment = null;
		foreach ( $segments as $s ) { if ( $s['key'] === $key ) { $segment = $s; break; } }

		$coupon_code = null;
		if ( $segment && ( $segment['prize_type'] ?? 'none' ) === 'coupon' ) {
			$coupon_code = Trinhs_FW_Coupon::mint( $segment, $email, $order_id );
		}

		Trinhs_FW_Store::set_result( $order_id, $key, $coupon_code );

		if ( $coupon_code ) {
			$order = wc_get_order( $order_id );
			if ( $order ) {
				$expires = ( new DateTime( '+' . Trinhs_FW_Config::coupon_validity_days() . ' days', wp_timezone() ) )->getTimestamp();
				do_action( 'trinhs_fw_won', $order, $coupon_code, $segment['discount_type'], (float) $segment['amount'], $expires );
			}
		}

		wp_send_json_success( self::result_payload( $key, $coupon_code ) );
	}

	private static function result_payload( $prize_key, $coupon_code ) {
		$label = $prize_key;
		foreach ( Trinhs_FW_Config::segments() as $s ) { if ( $s['key'] === $prize_key ) { $label = $s['label']; break; } }
		$is_win = ! empty( $coupon_code );
		return array(
			'is_win'      => $is_win,
			'prize_key'   => $prize_key,
			'prize_label' => $label,
			'coupon_code' => $coupon_code,
			'message'     => $is_win
				? sprintf( __( 'You won %1$s! Your code: %2$s (also emailed to you).', 'trinhs-fw' ), $label, $coupon_code )
				: __( 'Better luck next time — thank you so much for taking the time to share your feedback with us.', 'trinhs-fw' ),
		);
	}
}

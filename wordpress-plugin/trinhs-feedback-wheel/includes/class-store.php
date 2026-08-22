<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }

/**
 * Single plays table. One row per order (UNIQUE order_id) = one survey + one spin.
 */
final class Trinhs_FW_Store {

	public static function table() {
		global $wpdb;
		return $wpdb->prefix . 'trinhs_fw_plays';
	}

	public static function install() {
		global $wpdb;
		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		$table   = self::table();
		$collate = $wpdb->get_charset_collate();

		$sql = "CREATE TABLE {$table} (
			id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
			order_id BIGINT UNSIGNED NOT NULL,
			email VARCHAR(191) NOT NULL DEFAULT '',
			q1 TEXT NULL,
			q2 TEXT NULL,
			q3 TEXT NULL,
			prize_key VARCHAR(64) NULL,
			coupon_code VARCHAR(64) NULL,
			created_at DATETIME NOT NULL,
			PRIMARY KEY (id),
			UNIQUE KEY order_id (order_id),
			KEY email (email)
		) {$collate};";

		dbDelta( $sql );
	}

	public static function claim( int $order_id, string $email, array $answers ): bool {
		global $wpdb;
		$suppress = $wpdb->suppress_errors( true ); // duplicate-key is expected, don't log
		$ok = $wpdb->insert(
			self::table(),
			array(
				'order_id'    => $order_id,
				'email'       => substr( $email, 0, 191 ),
				'q1'          => isset( $answers[0] ) ? (string) $answers[0] : null,
				'q2'          => isset( $answers[1] ) ? (string) $answers[1] : null,
				'q3'          => isset( $answers[2] ) ? (string) $answers[2] : null,
				'prize_key'   => null,
				'coupon_code' => null,
				'created_at'  => current_time( 'mysql' ),
			),
			array( '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s' )
		);
		$wpdb->suppress_errors( $suppress );
		return (bool) $ok; // false when UNIQUE(order_id) collides
	}

	public static function set_result( int $order_id, string $prize_key, ?string $coupon_code ): void {
		global $wpdb;
		$wpdb->update(
			self::table(),
			array( 'prize_key' => $prize_key, 'coupon_code' => $coupon_code ),
			array( 'order_id' => $order_id ),
			array( '%s', '%s' ),
			array( '%d' )
		);
	}

	public static function get( int $order_id ): ?array {
		global $wpdb;
		$row = $wpdb->get_row(
			$wpdb->prepare( 'SELECT * FROM ' . self::table() . ' WHERE order_id = %d', $order_id ),
			ARRAY_A
		);
		return $row ?: null;
	}
}

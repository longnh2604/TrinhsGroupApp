<?php
if ( defined( 'ABSPATH' ) ? ! defined( 'ABSPATH' ) : false ) { exit; } // no-op guard; WP-independent

final class Trinhs_FW_Wheel {

	public static function total_weight( array $segments ): int {
		$t = 0;
		foreach ( $segments as $s ) { $t += (int) $s['weight']; }
		return $t;
	}

	public static function pick( array $segments, int $roll ): string {
		$cum  = 0;
		$last = '';
		foreach ( $segments as $s ) {
			$last = (string) $s['key'];
			$cum += (int) $s['weight'];
			if ( $roll < $cum ) {
				return (string) $s['key'];
			}
		}
		return $last; // clamp (roll >= total)
	}
}

<?php
if ( defined( 'ABSPATH' ) ? ! defined( 'ABSPATH' ) : false ) { exit; } // no-op guard; class is WP-independent

final class Trinhs_FW_Token {

	private static function b64url_encode( $bin ) {
		return rtrim( strtr( base64_encode( $bin ), '+/', '-_' ), '=' );
	}

	private static function b64url_decode( $str ) {
		return base64_decode( strtr( $str, '-_', '+/' ) );
	}

	public static function sign( array $payload, string $secret ): string {
		$body = self::b64url_encode( json_encode( $payload ) );
		$sig  = hash_hmac( 'sha256', $body, $secret );
		return $body . '.' . $sig;
	}

	public static function verify( string $token, string $secret ): ?array {
		$parts = explode( '.', $token );
		if ( count( $parts ) !== 2 ) { return null; }
		list( $body, $sig ) = $parts;
		$expected = hash_hmac( 'sha256', $body, $secret );
		if ( ! hash_equals( $expected, $sig ) ) { return null; }
		$decoded = json_decode( self::b64url_decode( $body ), true );
		return is_array( $decoded ) ? $decoded : null;
	}
}

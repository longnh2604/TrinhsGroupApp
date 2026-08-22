<?php
require __DIR__ . '/../includes/class-token.php';

$fail = 0;
function check( $cond, $msg ) { global $fail; if ( $cond ) { echo "PASS: $msg\n"; } else { echo "FAIL: $msg\n"; $fail++; } }

$secret  = 'test-secret-abc';
$payload = array( 'order_id' => 123, 'email' => 'a@b.com', 'iat' => 1000 );

$token = Trinhs_FW_Token::sign( $payload, $secret );
check( is_string( $token ) && strpos( $token, '.' ) !== false, 'sign returns dotted token' );

$out = Trinhs_FW_Token::verify( $token, $secret );
check( is_array( $out ) && (int) $out['order_id'] === 123 && $out['email'] === 'a@b.com', 'verify round-trips payload' );

check( Trinhs_FW_Token::verify( $token, 'wrong-secret' ) === null, 'wrong secret rejected' );

$tampered = substr( $token, 0, -2 ) . ( substr( $token, -1 ) === 'x' ? 'yy' : 'xx' );
check( Trinhs_FW_Token::verify( $tampered, $secret ) === null, 'tampered signature rejected' );

check( Trinhs_FW_Token::verify( 'garbage-no-dot', $secret ) === null, 'malformed token rejected' );

echo $fail ? "\n$fail FAILED\n" : "\nALL PASSED\n";
exit( $fail ? 1 : 0 );

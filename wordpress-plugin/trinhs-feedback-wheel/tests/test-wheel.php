<?php
require __DIR__ . '/../includes/class-wheel.php';

$fail = 0;
function check( $cond, $msg ) { global $fail; if ( $cond ) { echo "PASS: $msg\n"; } else { echo "FAIL: $msg\n"; $fail++; } }

$segments = array(
	array( 'key' => 'v50', 'weight' => 1 ),
	array( 'key' => 'v10', 'weight' => 4 ),
	array( 'key' => 'v5',  'weight' => 20 ),
	array( 'key' => 'p10', 'weight' => 20 ),
	array( 'key' => 'none','weight' => 355 ),
);

check( Trinhs_FW_Wheel::total_weight( $segments ) === 400, 'total weight = 400' );

// Boundary picks by cumulative weight: v50=[0], v10=[1..4], v5=[5..24], p10=[25..44], none=[45..399]
check( Trinhs_FW_Wheel::pick( $segments, 0 )   === 'v50',  'roll 0 -> v50' );
check( Trinhs_FW_Wheel::pick( $segments, 1 )   === 'v10',  'roll 1 -> v10' );
check( Trinhs_FW_Wheel::pick( $segments, 4 )   === 'v10',  'roll 4 -> v10' );
check( Trinhs_FW_Wheel::pick( $segments, 5 )   === 'v5',   'roll 5 -> v5' );
check( Trinhs_FW_Wheel::pick( $segments, 24 )  === 'v5',   'roll 24 -> v5' );
check( Trinhs_FW_Wheel::pick( $segments, 25 )  === 'p10',  'roll 25 -> p10' );
check( Trinhs_FW_Wheel::pick( $segments, 44 )  === 'p10',  'roll 44 -> p10' );
check( Trinhs_FW_Wheel::pick( $segments, 45 )  === 'none', 'roll 45 -> none' );
check( Trinhs_FW_Wheel::pick( $segments, 399 ) === 'none', 'roll 399 -> none' );

// Distribution: seeded, deterministic. 400k draws, expect within tolerance.
mt_srand( 42 );
$counts = array();
$N = 400000;
$total = Trinhs_FW_Wheel::total_weight( $segments );
for ( $i = 0; $i < $N; $i++ ) {
	$k = Trinhs_FW_Wheel::pick( $segments, mt_rand( 0, $total - 1 ) );
	$counts[ $k ] = ( $counts[ $k ] ?? 0 ) + 1;
}
$p50 = $counts['v50'] / $N; // expect ~0.0025
check( $p50 > 0.0018 && $p50 < 0.0033, 'v50 frequency ~0.25% (got ' . round( $p50 * 100, 3 ) . '%)' );
$pnone = $counts['none'] / $N; // expect ~0.8875
check( $pnone > 0.87 && $pnone < 0.905, 'none frequency ~88.75% (got ' . round( $pnone * 100, 2 ) . '%)' );

echo $fail ? "\n$fail FAILED\n" : "\nALL PASSED\n";
exit( $fail ? 1 : 0 );

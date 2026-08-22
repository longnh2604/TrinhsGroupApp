<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }

final class Trinhs_FW_Admin {
	public static function init() {
		add_action( 'admin_menu', array( __CLASS__, 'menu' ) );
		add_action( 'admin_init', array( __CLASS__, 'maybe_save' ) );
	}

	public static function menu() {
		add_submenu_page(
			'woocommerce',
			"Trinh's Feedback Wheel",
			'Feedback Wheel',
			'manage_woocommerce',
			'trinhs-fw',
			array( __CLASS__, 'render' )
		);
		add_submenu_page(
			'woocommerce',
			'Feedback Responses',
			'Feedback Responses',
			'manage_woocommerce',
			'trinhs-fw-responses',
			array( __CLASS__, 'render_responses' )
		);
	}

	/** Read-only list of survey submissions + quick stats. */
	public static function render_responses() {
		global $wpdb;
		$table    = Trinhs_FW_Store::table();
		$per_page = 20;
		$paged    = isset( $_GET['paged'] ) ? max( 1, (int) $_GET['paged'] ) : 1;

		$total = (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$table}" );
		$rows  = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$table} ORDER BY created_at DESC LIMIT %d OFFSET %d",
				$per_page,
				( $paged - 1 ) * $per_page
			),
			ARRAY_A
		);

		$questions = Trinhs_FW_Config::questions();

		// Average star rating per rating-type question (only 1-5 numeric answers).
		$avgs = array();
		foreach ( array( 'q1', 'q2', 'q3' ) as $i => $col ) {
			if ( ( $questions[ $i ]['type'] ?? '' ) === 'rating' ) {
				$avgs[ $i ] = $wpdb->get_var( "SELECT ROUND(AVG({$col}+0),2) FROM {$table} WHERE {$col} REGEXP '^[1-5]$'" );
			}
		}

		// Prize distribution.
		$prize_counts = $wpdb->get_results( "SELECT prize_key, COUNT(*) AS c FROM {$table} GROUP BY prize_key ORDER BY c DESC", ARRAY_A );
		$seg_labels   = array();
		foreach ( Trinhs_FW_Config::segments() as $s ) { $seg_labels[ $s['key'] ] = $s['label']; }
		?>
		<div class="wrap">
			<h1>Feedback Responses</h1>

			<p>
				<strong><?php echo (int) $total; ?></strong> responses total.
				<?php foreach ( $avgs as $i => $avg ) : if ( null !== $avg ) : ?>
					&nbsp;|&nbsp; <?php echo esc_html( $questions[ $i ]['label'] ); ?>: <strong><?php echo esc_html( $avg ); ?> ★</strong>
				<?php endif; endforeach; ?>
			</p>

			<?php if ( $prize_counts ) : ?>
			<p>
				<?php foreach ( $prize_counts as $pc ) : ?>
					<span style="display:inline-block;margin-right:14px;">
						<?php echo esc_html( $seg_labels[ $pc['prize_key'] ] ?? ( $pc['prize_key'] ?: 'pending' ) ); ?>:
						<strong><?php echo (int) $pc['c']; ?></strong>
					</span>
				<?php endforeach; ?>
			</p>
			<?php endif; ?>

			<table class="widefat striped">
				<thead>
					<tr>
						<th>Date</th>
						<th>Order</th>
						<th>Email</th>
						<th><?php echo esc_html( $questions[0]['label'] ?? 'Q1' ); ?></th>
						<th><?php echo esc_html( $questions[1]['label'] ?? 'Q2' ); ?></th>
						<th><?php echo esc_html( $questions[2]['label'] ?? 'Q3' ); ?></th>
						<th>Prize</th>
						<th>Coupon</th>
					</tr>
				</thead>
				<tbody>
				<?php if ( ! $rows ) : ?>
					<tr><td colspan="8">No responses yet.</td></tr>
				<?php else : foreach ( $rows as $r ) :
					$order     = function_exists( 'wc_get_order' ) ? wc_get_order( (int) $r['order_id'] ) : false;
					$order_url = $order && method_exists( $order, 'get_edit_order_url' ) ? $order->get_edit_order_url() : '';
					?>
					<tr>
						<td><?php echo esc_html( $r['created_at'] ); ?></td>
						<td>
							<?php if ( $order_url ) : ?>
								<a href="<?php echo esc_url( $order_url ); ?>">#<?php echo (int) $r['order_id']; ?></a>
							<?php else : ?>
								#<?php echo (int) $r['order_id']; ?>
							<?php endif; ?>
						</td>
						<td><?php echo esc_html( $r['email'] ); ?></td>
						<?php foreach ( array( 'q1', 'q2', 'q3' ) as $qi => $col ) :
							$val    = (string) $r[ $col ];
							$is_num = ( $questions[ $qi ]['type'] ?? '' ) === 'rating' && preg_match( '/^[1-5]$/', $val );
							?>
							<td title="<?php echo esc_attr( $val ); ?>">
								<?php echo $is_num
									? esc_html( $val ) . ' ★'
									: esc_html( mb_strimwidth( $val, 0, 80, '…' ) ); ?>
							</td>
						<?php endforeach; ?>
						<td><?php echo esc_html( $seg_labels[ $r['prize_key'] ] ?? ( $r['prize_key'] ?: '—' ) ); ?></td>
						<td><?php echo $r['coupon_code'] ? '<code>' . esc_html( $r['coupon_code'] ) . '</code>' : '—'; ?></td>
					</tr>
				<?php endforeach; endif; ?>
				</tbody>
			</table>

			<?php
			$pages = (int) ceil( $total / $per_page );
			if ( $pages > 1 ) {
				echo '<p>';
				for ( $p = 1; $p <= $pages; $p++ ) {
					$url = add_query_arg( array( 'page' => 'trinhs-fw-responses', 'paged' => $p ), admin_url( 'admin.php' ) );
					echo $p === $paged
						? '<strong style="margin-right:8px;">' . (int) $p . '</strong>'
						: '<a style="margin-right:8px;" href="' . esc_url( $url ) . '">' . (int) $p . '</a>';
				}
				echo '</p>';
			}
			?>
		</div>
		<?php
	}

	public static function maybe_save() {
		if ( ! isset( $_POST['trinhs_fw_save'] ) ) { return; }
		if ( ! current_user_can( 'manage_woocommerce' ) ) { return; }
		check_admin_referer( 'trinhs_fw_settings' );

		$in       = wp_unslash( $_POST );
		$settings = Trinhs_FW_Config::get();

		$settings['enabled']            = empty( $in['enabled'] ) ? 0 : 1;
		$settings['link_validity_days'] = max( 1, (int) $in['link_validity_days'] );
		$settings['coupon_validity']    = max( 1, (int) $in['coupon_validity'] );
		$settings['coupon_min_spend']   = (float) $in['coupon_min_spend'];
		$settings['review_google_url']  = esc_url_raw( $in['review_google_url'] );
		$settings['review_website_url'] = esc_url_raw( $in['review_website_url'] );
		$settings['feedback_page_id']   = (int) $in['feedback_page_id'];

		$q = array();
		foreach ( array( 0, 1, 2 ) as $i ) {
			$q[] = array(
				'label'   => sanitize_text_field( $in['q_label'][ $i ] ?? '' ),
				'type'    => in_array( $in['q_type'][ $i ] ?? 'rating', array( 'rating', 'choice', 'text' ), true ) ? $in['q_type'][ $i ] : 'rating',
				'choices' => array_filter( array_map( 'sanitize_text_field', explode( '|', $in['q_choices'][ $i ] ?? '' ) ) ),
			);
		}
		$settings['questions'] = $q;

		$segs = array();
		$keys = $in['seg_key'] ?? array();
		foreach ( $keys as $i => $key ) {
			$segs[] = array(
				'key'           => sanitize_key( $key ),
				'label'         => sanitize_text_field( $in['seg_label'][ $i ] ?? '' ),
				'prize_type'    => ( ( $in['seg_prize_type'][ $i ] ?? 'none' ) === 'coupon' ) ? 'coupon' : 'none',
				'discount_type' => in_array( $in['seg_discount_type'][ $i ] ?? '', array( 'fixed_cart', 'percent' ), true ) ? $in['seg_discount_type'][ $i ] : '',
				'amount'        => (float) ( $in['seg_amount'][ $i ] ?? 0 ),
				'weight'        => max( 0, (int) ( $in['seg_weight'][ $i ] ?? 0 ) ),
			);
		}
		if ( $segs ) { $settings['segments'] = $segs; }

		update_option( Trinhs_FW_Config::OPTION, $settings );
		add_action( 'admin_notices', function () {
			echo '<div class="notice notice-success is-dismissible"><p>Feedback Wheel settings saved.</p></div>';
		} );
	}

	public static function render() {
		$c     = Trinhs_FW_Config::get();
		$total = 0;
		foreach ( $c['segments'] as $s ) { $total += (int) $s['weight']; }
		?>
		<div class="wrap">
			<h1>Trinh's Feedback Wheel</h1>
			<form method="post">
				<?php wp_nonce_field( 'trinhs_fw_settings' ); ?>
				<table class="form-table">
					<tr><th>Enabled</th><td><label><input type="checkbox" name="enabled" value="1" <?php checked( $c['enabled'], 1 ); ?>> Send invites &amp; allow play</label></td></tr>
					<tr><th>Link validity (days)</th><td><input type="number" name="link_validity_days" value="<?php echo esc_attr( $c['link_validity_days'] ); ?>" min="1"></td></tr>
					<tr><th>Coupon validity (days)</th><td><input type="number" name="coupon_validity" value="<?php echo esc_attr( $c['coupon_validity'] ); ?>" min="1"></td></tr>
					<tr><th>Coupon min spend</th><td><input type="number" step="0.01" name="coupon_min_spend" value="<?php echo esc_attr( $c['coupon_min_spend'] ); ?>"></td></tr>
					<tr><th>Google review URL</th><td><input type="url" class="regular-text" name="review_google_url" value="<?php echo esc_attr( $c['review_google_url'] ); ?>"></td></tr>
					<tr><th>Website review URL</th><td><input type="url" class="regular-text" name="review_website_url" value="<?php echo esc_attr( $c['review_website_url'] ); ?>"></td></tr>
					<tr><th>Feedback page</th><td><?php wp_dropdown_pages( array( 'name' => 'feedback_page_id', 'selected' => $c['feedback_page_id'], 'show_option_none' => '— select —', 'option_none_value' => 0 ) ); ?></td></tr>
				</table>

				<h2>Survey questions</h2>
				<table class="widefat"><thead><tr><th>Label</th><th>Type</th><th>Choices (a|b|c, for choice type)</th></tr></thead><tbody>
				<?php foreach ( array( 0, 1, 2 ) as $i ) : $q = $c['questions'][ $i ] ?? array( 'label' => '', 'type' => 'rating', 'choices' => array() ); ?>
					<tr>
						<td><input type="text" class="regular-text" name="q_label[<?php echo $i; ?>]" value="<?php echo esc_attr( $q['label'] ); ?>"></td>
						<td><select name="q_type[<?php echo $i; ?>]">
							<?php foreach ( array( 'rating', 'choice', 'text' ) as $t ) : ?>
								<option value="<?php echo $t; ?>" <?php selected( $q['type'], $t ); ?>><?php echo $t; ?></option>
							<?php endforeach; ?>
						</select></td>
						<td><input type="text" class="regular-text" name="q_choices[<?php echo $i; ?>]" value="<?php echo esc_attr( implode( '|', (array) $q['choices'] ) ); ?>"></td>
					</tr>
				<?php endforeach; ?>
				</tbody></table>

				<h2>Wheel segments (total weight = <?php echo (int) $total; ?>)</h2>
				<table class="widefat"><thead><tr><th>Key</th><th>Label</th><th>Prize</th><th>Discount type</th><th>Amount</th><th>Weight</th><th>Probability</th></tr></thead><tbody>
				<?php foreach ( $c['segments'] as $i => $s ) :
					$pct = $total ? round( 100 * $s['weight'] / $total, 3 ) : 0; ?>
					<tr>
						<td><input type="text" name="seg_key[<?php echo $i; ?>]" value="<?php echo esc_attr( $s['key'] ); ?>" size="6"></td>
						<td><input type="text" name="seg_label[<?php echo $i; ?>]" value="<?php echo esc_attr( $s['label'] ); ?>"></td>
						<td><select name="seg_prize_type[<?php echo $i; ?>]">
							<option value="none" <?php selected( $s['prize_type'], 'none' ); ?>>none</option>
							<option value="coupon" <?php selected( $s['prize_type'], 'coupon' ); ?>>coupon</option>
						</select></td>
						<td><select name="seg_discount_type[<?php echo $i; ?>]">
							<option value="" <?php selected( $s['discount_type'], '' ); ?>>—</option>
							<option value="fixed_cart" <?php selected( $s['discount_type'], 'fixed_cart' ); ?>>fixed_cart</option>
							<option value="percent" <?php selected( $s['discount_type'], 'percent' ); ?>>percent</option>
						</select></td>
						<td><input type="number" step="0.01" name="seg_amount[<?php echo $i; ?>]" value="<?php echo esc_attr( $s['amount'] ); ?>" size="5"></td>
						<td><input type="number" name="seg_weight[<?php echo $i; ?>]" value="<?php echo esc_attr( $s['weight'] ); ?>" size="5"></td>
						<td><strong><?php echo esc_html( $pct ); ?>%</strong></td>
					</tr>
				<?php endforeach; ?>
				</tbody></table>

				<p><button class="button button-primary" name="trinhs_fw_save" value="1">Save settings</button></p>
			</form>
		</div>
		<?php
	}
}

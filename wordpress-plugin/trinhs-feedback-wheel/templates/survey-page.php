<?php if ( ! defined( 'ABSPATH' ) ) { exit; } ?>
<div class="trinhs-fw" id="trinhs-fw">
	<form id="trinhs-fw-form" class="trinhs-fw-form">
		<?php foreach ( $questions as $i => $q ) :
			$n = $i + 1; ?>
			<div class="trinhs-fw-q">
				<label class="trinhs-fw-label"><?php echo esc_html( $q['label'] ); ?></label>
				<?php if ( 'rating' === $q['type'] ) : ?>
					<div class="trinhs-fw-stars" data-q="q<?php echo (int) $n; ?>">
						<?php for ( $s = 1; $s <= 5; $s++ ) : ?>
							<span class="trinhs-fw-star" data-v="<?php echo (int) $s; ?>">&#9733;</span>
						<?php endfor; ?>
					</div>
					<input type="hidden" name="q<?php echo (int) $n; ?>" value="">
				<?php elseif ( 'choice' === $q['type'] ) : ?>
					<select name="q<?php echo (int) $n; ?>">
						<option value=""><?php esc_html_e( 'Please choose…', 'trinhs-fw' ); ?></option>
						<?php foreach ( (array) $q['choices'] as $c ) : ?>
							<option value="<?php echo esc_attr( $c ); ?>"><?php echo esc_html( $c ); ?></option>
						<?php endforeach; ?>
					</select>
				<?php else : ?>
					<textarea name="q<?php echo (int) $n; ?>" rows="3" maxlength="1000"></textarea>
				<?php endif; ?>
			</div>
		<?php endforeach; ?>

		<?php if ( $google_url || $website_url ) : ?>
			<div class="trinhs-fw-review">
				<p><?php esc_html_e( 'Loved your meal? A quick review really helps us (optional):', 'trinhs-fw' ); ?></p>
				<?php if ( $google_url ) : ?>
					<a class="trinhs-fw-review-btn" href="<?php echo esc_url( $google_url ); ?>" target="_blank" rel="noopener">★ <?php esc_html_e( 'Review us on Google', 'trinhs-fw' ); ?></a>
				<?php endif; ?>
				<?php if ( $website_url ) : ?>
					<a class="trinhs-fw-review-btn" href="<?php echo esc_url( $website_url ); ?>" target="_blank" rel="noopener"><?php esc_html_e( 'Review on our website', 'trinhs-fw' ); ?></a>
				<?php endif; ?>
			</div>
		<?php endif; ?>

		<button type="submit" class="trinhs-fw-submit"><?php esc_html_e( 'Submit & spin the wheel', 'trinhs-fw' ); ?></button>
		<p class="trinhs-fw-error" role="alert"></p>
	</form>

	<div class="trinhs-fw-wheel-wrap" hidden>
		<div class="trinhs-fw-wheel" id="trinhs-fw-wheel"></div>
		<div class="trinhs-fw-pointer"></div>
	</div>
	<div class="trinhs-fw-result" hidden></div>
</div>

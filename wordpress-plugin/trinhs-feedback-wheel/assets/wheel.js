(function () {
	var cfg = window.TRINHS_FW;
	if (!cfg) return;
	var form = document.getElementById('trinhs-fw-form');
	var wheelWrap = document.querySelector('.trinhs-fw-wheel-wrap');
	var wheelEl = document.getElementById('trinhs-fw-wheel');
	var resultEl = document.querySelector('.trinhs-fw-result');
	var errEl = document.querySelector('.trinhs-fw-error');
	var segs = cfg.segments || [];

	// Paint the wheel as equal-sized visual slices (cosmetic only),
	// then place each prize label centred inside its own slice.
	(function paint() {
		var n = segs.length || 1, step = 360 / n, stops = [];
		var palette = ['#b8232f', '#e0a53b', '#2e7d5b', '#3b6ea5', '#7a4fa0', '#d98324'];
		for (var i = 0; i < n; i++) {
			stops.push(palette[i % palette.length] + ' ' + (i * step) + 'deg ' + ((i + 1) * step) + 'deg');
		}
		wheelEl.style.background = 'conic-gradient(' + stops.join(',') + ')';

		// Labels: one box per slice, rotated to the slice's mid-angle and pushed
		// outward along the radius so it sits centred in the slice. Font size
		// scales down for longer labels so text never gets cut.
		var radius = wheelEl.clientWidth / 2 || 160;
		var labelR = Math.round(radius * 0.62);            // label centre distance from wheel centre
		var maxW   = Math.round(2 * labelR * Math.sin(Math.PI / n) * 0.82); // 82% of chord width at labelR
		for (var j = 0; j < n; j++) {
			var mid = j * step + step / 2;
			var el = document.createElement('div');
			el.className = 'trinhs-fw-slice-label';
			el.textContent = segs[j].label || '';
			var len = (segs[j].label || '').length;
			el.style.fontSize = (len <= 10 ? 15 : len <= 16 ? 13 : 11) + 'px';
			el.style.width = maxW + 'px';
			el.style.transform = 'translate(-50%, -50%) rotate(' + mid + 'deg) translateY(-' + labelR + 'px)';
			wheelEl.appendChild(el);
		}
	})();

	// Star rating widgets.
	document.querySelectorAll('.trinhs-fw-stars').forEach(function (grp) {
		var input = grp.parentNode.querySelector('input[type=hidden]');
		grp.querySelectorAll('.trinhs-fw-star').forEach(function (star) {
			star.addEventListener('click', function () {
				var v = parseInt(star.getAttribute('data-v'), 10);
				input.value = v;
				grp.querySelectorAll('.trinhs-fw-star').forEach(function (s) {
					s.classList.toggle('on', parseInt(s.getAttribute('data-v'), 10) <= v);
				});
			});
		});
	});

	function spinTo(prizeKey, done) {
		var idx = segs.findIndex(function (s) { return s.key === prizeKey; });
		if (idx < 0) idx = segs.length - 1;
		var step = 360 / (segs.length || 1);
		var target = 360 * 6 + (360 - (idx * step + step / 2)); // land pointer (top) on slice centre
		wheelWrap.hidden = false;
		requestAnimationFrame(function () { wheelEl.style.transform = 'rotate(' + target + 'deg)'; });
		setTimeout(done, 4200);
	}

	form.addEventListener('submit', function (e) {
		e.preventDefault();
		errEl.textContent = '';
		var btn = form.querySelector('.trinhs-fw-submit');
		btn.disabled = true;

		var body = new URLSearchParams();
		body.set('action', 'trinhs_fw_submit');
		body.set('nonce', cfg.nonce);
		body.set('token', cfg.token);
		body.set('q1', (form.q1 && form.q1.value) || '');
		body.set('q2', (form.q2 && form.q2.value) || '');
		body.set('q3', (form.q3 && form.q3.value) || '');

		fetch(cfg.ajax_url, { method: 'POST', body: body, credentials: 'same-origin' })
			.then(function (r) { return r.json(); })
			.then(function (res) {
				if (!res.success) { throw new Error((res.data && res.data.message) || 'Error'); }
				var d = res.data;
				form.hidden = true;
				spinTo(d.prize_key, function () {
					resultEl.hidden = false;
					if (d.is_win) {
						resultEl.innerHTML = '<p>' + d.message.replace(d.coupon_code, '') + '</p><strong>' + d.coupon_code + '</strong>';
					} else {
						resultEl.textContent = d.message;
					}
				});
			})
			.catch(function (err) { btn.disabled = false; errEl.textContent = err.message; });
	});
})();

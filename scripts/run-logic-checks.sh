#!/usr/bin/env bash
#
# run-logic-checks.sh — compile-and-assert checks over the app's pure logic.
#
# These are NOT a substitute for an XCTest target; the project has none (adding one means
# a new target in project.pbxproj). What this does give is regression cover for the
# self-contained logic that has actually broken in the past, runnable from CI with nothing
# but the Swift toolchain — no simulator, no network, no Keychain, no signing.
#
# Each suite compiles the REAL source file (or extracts the real function from it) rather
# than a copy, so a check can never silently drift from the code it is asserting on. If a
# function is renamed or moved, extraction fails and the suite errors instead of passing.
#
#   ./scripts/run-logic-checks.sh
#
# Exit 0 = all suites passed. Exit 1 = a failure. Exit 2 = harness/setup problem.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/TrinhsGroup"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

command -v swiftc >/dev/null || { echo "swiftc not found — install Xcode command line tools" >&2; exit 2; }
command -v python3 >/dev/null || { echo "python3 not found" >&2; exit 2; }

BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; DIM=$'\033[2m'; OFF=$'\033[0m'
SUITES_RUN=0; SUITES_FAILED=0

run_suite() {  # run_suite <name> <dir>
    local name="$1" dir="$2"
    SUITES_RUN=$((SUITES_RUN + 1))
    printf '\n%s%s%s\n' "$BOLD" "$name" "$OFF"
    if ! swiftc -O "$dir"/*.swift -o "$dir/run" 2>"$dir/build.err"; then
        printf '  %s✗ failed to compile%s\n' "$RED" "$OFF"
        sed 's/^/    /' "$dir/build.err" | head -20
        SUITES_FAILED=$((SUITES_FAILED + 1)); return
    fi
    if "$dir/run"; then :; else
        SUITES_FAILED=$((SUITES_FAILED + 1))
    fi
}

# ── Suite 1: discount percentage ────────────────────────────────────────────────
# Regression cover for two defects: misplaced parentheses that rendered a $10→$8 sale as
# "99% OFF", and a divide-by-zero that trapped on products WooCommerce sends with an empty
# regular_price (ProductModel decodes that to 0).
suite_discount() {
    local d="$WORK/discount"; mkdir -p "$d"
    python3 - "$SRC/Utility/Constant.swift" "$d/subject.swift" <<'PY' || exit 2
import sys
src = open(sys.argv[1]).read().split('\n')
try:
    s = next(i for i, l in enumerate(src) if l.startswith('func getDiscountPercentage'))
except StopIteration:
    sys.exit("getDiscountPercentage not found in Constant.swift — did it move or get renamed?")
e = next(i for i, l in enumerate(src[s:], start=s) if l == '}')
open(sys.argv[2], 'w').write('import Foundation\n\n' + '\n'.join(src[s:e + 1]) + '\n')
PY
    cat > "$d/main.swift" <<'SWIFT'
import Foundation
var fails = 0
func expect(_ reg: Double, _ sale: Double, _ want: String) {
    let got = getDiscountPercentage(regularPrice: reg, salePrice: sale)
    if got == want { print("  ✓ regular \(reg) / sale \(sale) → \"\(got)\"") }
    else { fails += 1; print("  ✗ regular \(reg) / sale \(sale) → \"\(got)\", expected \"\(want)\"") }
}
expect(10, 8, "20% OFF")        // was "99% OFF"
expect(10, 5, "50% OFF")
expect(25.5, 20, "21% OFF")
expect(100, 1, "99% OFF")
expect(0, 5, "")                // regular_price "" → 0 → used to trap on Int(inf)
expect(10, 0, "")               // was "100% OFF"
expect(10, 10, "")
expect(10, 12, "")
exit(fails == 0 ? 0 : 1)
SWIFT
    run_suite "getDiscountPercentage" "$d"
}

# ── Suite 2: points response decoding ──────────────────────────────────────────
# The balance is read from bu/v1/me/points. It was previously scraped out of the customer
# record's meta_data, which WooCommerce only emits for administrators — so the app started
# failing to decode it the moment it authenticated as the customer instead.
suite_points_decode() {
    local d="$WORK/points"; mkdir -p "$d"
    cp "$SRC/View/Model/PointsResponse.swift" "$d/" || exit 2
    cat > "$d/main.swift" <<'SWIFT'
import Foundation
var fails = 0
func expectDecodes(_ label: String, _ json: String, _ shouldSucceed: Bool) {
    let ok: Bool
    var note = ""
    do {
        let r = try JSONDecoder().decode(PointsResponse.self, from: Data(json.utf8))
        ok = shouldSucceed; note = "userId=\(r.userId) balance=\(r.balance)"
    } catch {
        ok = !shouldSucceed; note = (error as NSError).localizedDescription
    }
    if ok { print("  ✓ \(label)  → \(note)") }
    else { fails += 1; print("  ✗ \(label)  → \(note)") }
}
expectDecodes("bu/v1/me/points payload",  #"{"user_id":1,"type":"mycred_default","balance":40}"#,   true)
expectDecodes("fractional balance",       #"{"user_id":1,"type":"mycred_default","balance":40.5}"#, true)
expectDecodes("zero balance",             #"{"user_id":1,"type":"mycred_default","balance":0}"#,    true)
expectDecodes("customer object w/o meta_data must NOT decode",
              #"{"id":1,"email":"a@b.c","role":"customer"}"#, false)
expectDecodes("mycred error body must NOT decode as points",
              #"{"error":"mycred_not_available"}"#, false)
exit(fails == 0 ? 0 : 1)
SWIFT
    run_suite "PointsResponse decoding" "$d"
}

suite_discount
suite_points_decode

printf '\n%s────────────────────────────%s\n' "$BOLD" "$OFF"
if [[ $SUITES_FAILED -eq 0 ]]; then
    printf '%sall %s suite(s) passed%s\n' "$GREEN" "$SUITES_RUN" "$OFF"
    exit 0
fi
printf '%s%s of %s suite(s) failed%s\n' "$RED" "$SUITES_FAILED" "$SUITES_RUN" "$OFF"
exit 1

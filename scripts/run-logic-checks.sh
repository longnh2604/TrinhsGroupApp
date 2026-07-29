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

# ── Suite: AppNotification decoding ─────────────────────────────────────────────
# The bell history is persisted in UserDefaults on real devices, so this struct must keep
# decoding entries written by older builds. A throw here would silently empty a customer's
# notification list.
suite_notification_decode() {
    local d="$WORK/notification"; mkdir -p "$d"
    python3 - "$SRC/View/Model/NotificationModel.swift" "$d/subject.swift" <<'PY' || exit 2
import sys
src = open(sys.argv[1]).read().split('\n')
try:
    s = next(i for i, l in enumerate(src) if l.startswith('struct AppNotification'))
except StopIteration:
    sys.exit("struct AppNotification not found — did it move or get renamed?")
e = next(i for i, l in enumerate(src[s:], start=s) if l == '}')
open(sys.argv[2], 'w').write('import Foundation\n\n' + '\n'.join(src[s:e + 1]) + '\n')
PY
    cat > "$d/main.swift" <<'SWIFT'
import Foundation
var fails = 0
func check(_ ok: Bool, _ what: String, _ detail: String = "") {
    print("  \(ok ? "✓" : "✗") \(what)\(detail.isEmpty ? "" : "  → \(detail)")")
    if !ok { fails += 1 }
}
func decode(_ json: String) -> AppNotification? {
    try? JSONDecoder().decode(AppNotification.self, from: Data(json.utf8))
}

// Entry written by a build that had no orderID at all.
if let n = decode(#"{"id":"abc","title":"Order Ready","content":"Order #12 is complete.","isRead":true}"#) {
    check(n.orderID == nil, "legacy entry (no orderID) decodes with orderID == nil", "\(String(describing: n.orderID))")
    check(n.title == "Order Ready", "legacy entry keeps its title")
} else { check(false, "legacy entry (no orderID) decodes") }

// Oldest format: integer id, no date/isRead. Existing compatibility path.
if let n = decode(#"{"id":7,"title":"T","content":"C"}"#) {
    check(n.id == "7", "legacy Int id still coerces to String", n.id)
    check(n.isRead == true, "legacy entry defaults to read")
    check(n.orderID == nil, "legacy Int-id entry has no orderID")
} else { check(false, "legacy Int-id entry decodes") }

// New format.
if let n = decode(#"{"id":"abc","title":"T","content":"C","isRead":false,"orderID":1234}"#) {
    check(n.orderID == 1234, "new entry decodes orderID", "\(String(describing: n.orderID))")
} else { check(false, "new entry with orderID decodes") }

// Round trip.
let original = AppNotification(id: "x", title: "T", content: "C", isRead: false, orderID: 99)
if let data = try? JSONEncoder().encode(original), let back = decode(String(data: data, encoding: .utf8)!) {
    check(back.orderID == 99, "orderID survives encode → decode", "\(String(describing: back.orderID))")
} else { check(false, "orderID survives encode → decode") }

// Payload parsing: the plugin sends order_id as a STRING.
check(AppNotification.orderID(from: ["order_id": "1234"]) == 1234, "userInfo string \"1234\" → 1234")
check(AppNotification.orderID(from: ["order_id": 1234]) == 1234, "userInfo Int 1234 → 1234")
check(AppNotification.orderID(from: [:]) == nil, "userInfo without order_id → nil")
check(AppNotification.orderID(from: ["order_id": "not-a-number"]) == nil, "non-numeric order_id → nil")
check(AppNotification.orderID(from: ["order_id": ""]) == nil, "empty order_id → nil")

print(fails == 0 ? "\n  ALL PASS" : "\n  \(fails) FAILURE(S)")
exit(fails == 0 ? 0 : 1)
SWIFT
    run_suite "AppNotification decoding" "$d"
}

# ── Suite: order status presentation ───────────────────────────────────────────
# The single source of truth for what an order status says, which animation it shows and
# which stage it has reached. None of it is reachable from a unit test through the app, and
# all of it fails quietly: a wrong lottieName is a blank hero, a wrongly-terminal status
# silently trims the rail, and a wrong stage mapping just draws the wrong node as current.
#
# Colours are NOT asserted — Color(hex:) is stubbed so the real file can compile without
# dragging in Utility/Extensions.swift. Tint correctness stays a visual check.
suite_order_status_presentation() {
    local d="$WORK/orderstatus"; mkdir -p "$d"
    python3 - "$SRC/View/Profile/OrderStatusPresentation.swift" "$d/subject.swift" <<'PY' || exit 2
import sys
src = open(sys.argv[1]).read().split('\n')
try:
    s = next(i for i, l in enumerate(src) if l.startswith('enum OrderStage'))
except StopIteration:
    sys.exit("enum OrderStage not found in OrderStatusPresentation.swift — did it move or get renamed?")
prelude = '''import SwiftUI

// The real init(hex:) lives in Utility/Extensions.swift, which would pull in the whole app.
// Colours are therefore not assertable here — see this suite's header.
extension Color { init(hex: String) { self = .clear } }

// Only the three fields fallbackEvents reads. If OrderModel renames or retypes one of them
// this suite stops compiling, rather than quietly testing a shape the app no longer has.
struct Order { var status: String; var dateCreated: String; var dateModified: String }

'''
open(sys.argv[2], 'w').write(prelude + '\n'.join(src[s:]) + '\n')
PY
    cp "$SRC/View/Model/OrderStatusHistoryModel.swift" "$d/" || exit 2
    cat > "$d/main.swift" <<'SWIFT'
import Foundation

var fails = 0
func check(_ ok: Bool, _ what: String, _ detail: String = "") {
    print("  \(ok ? "✓" : "✗") \(what)\(detail.isEmpty ? "" : "  → \(detail)")")
    if !ok { fails += 1 }
}
func labels(_ steps: [OrderStep]) -> [String] {
    steps.map {
        switch $0.state {
        case .done:     return "done"
        case .current:  return "current"
        case .upcoming: return "upcoming"
        }
    }
}

// ── The mapping table ──────────────────────────────────────────────────────────
func expectPresentation(_ status: String, _ title: String, _ lottie: String?, _ terminal: Bool) {
    let p = OrderStatusPresentation(status: status)
    check(p.title == title, "\(status) → \"\(title)\"", p.title)
    check(p.lottieName == lottie, "\(status) → lottie \(lottie ?? "nil")", p.lottieName ?? "nil")
    check(p.isTerminal == terminal, "\(status) → isTerminal \(terminal)", "\(p.isTerminal)")
}

expectPresentation("pending",    "Awaiting Payment", nil,                false)
expectPresentation("on-hold",    "Order Received",   "Order_onHold",     false)
expectPresentation("processing", "In the Kitchen",   "Order_processing", false)
expectPresentation("completed",  "Ready for Pickup", "Order_ready",      false)
expectPresentation("cancelled",  "Order Cancelled",  nil,                true)
expectPresentation("refunded",   "Order Refunded",   "Order_refunded",   true)
expectPresentation("failed",     "Payment Failed",   "Order_failed",     true)

// A status wp-admin has but the app does not model: show the slug, do not guess a stage.
expectPresentation("kitchen-hold", "Kitchen Hold", nil, false)

let modelled = ["pending", "on-hold", "processing", "completed", "cancelled", "refunded", "failed"]
check(modelled.filter { OrderStatusPresentation(status: $0).isTerminal } == ["cancelled", "refunded", "failed"],
      "exactly cancelled/refunded/failed are terminal")

// ── Every named animation is actually bundled ──────────────────────────────────
// LottieAnimation.named returns nil for a missing file, so a typo or a renamed asset is an
// invisible blank hero rather than a crash. Nothing else in the build catches this.
if let resources = ProcessInfo.processInfo.environment["TRINH_RESOURCES"] {
    for status in modelled {
        guard let name = OrderStatusPresentation(status: status).lottieName else { continue }
        check(FileManager.default.fileExists(atPath: "\(resources)/\(name).json"),
              "\(name).json is bundled")
    }
} else {
    check(false, "TRINH_RESOURCES was not passed to this suite")
}

// ── Stage mapping ─────────────────────────────────────────────────────────────
func expectStage(_ status: String, _ want: OrderStage?) {
    let got = OrderStage(status: status)
    check(got == want,
          "\(status) → stage \(want.map { "\($0)" } ?? "nil")",
          got.map { "\($0)" } ?? "nil")
}
expectStage("placed", .placed)
// Deliberate, and the most likely thing for someone to "fix": an unpaid order has been
// placed but confirmed by nobody, so pending must NOT reach .received.
expectStage("pending", .placed)
expectStage("on-hold", .received)
expectStage("processing", .cooking)
expectStage("completed", .ready)
expectStage("cancelled", nil)
expectStage("refunded", nil)
expectStage("failed", nil)
expectStage("kitchen-hold", nil)

// ── The rail reduction ────────────────────────────────────────────────────────
func ev(_ status: String, _ time: String?) -> OrderTimelineEvent {
    OrderTimelineEvent(status: status, displayTime: time)
}

let cooking = OrderProgressBuilder.steps(status: "processing", events: [
    ev("placed", "28 Jul, 6:00 PM"), ev("on-hold", "28 Jul, 6:05 PM"), ev("processing", "28 Jul, 6:10 PM"),
])
check(cooking.count == 4, "processing → 4 nodes", "\(cooking.count)")
check(labels(cooking) == ["done", "done", "current", "upcoming"], "processing → done/done/current/upcoming")
check(cooking[0].timestamp == "28 Jul, 6:00 PM", "a reached node keeps its timestamp", cooking[0].timestamp ?? "nil")
check(cooking[3].timestamp == nil, "an unreached node has no timestamp")
check(cooking.allSatisfy { !$0.isTerminal }, "a live order appends no terminal node")

let awaiting = OrderProgressBuilder.steps(status: "pending", events: [ev("placed", "28 Jul, 6:00 PM")])
check(labels(awaiting) == ["current", "upcoming", "upcoming", "upcoming"], "pending sits on node 1")

// Cancelled after it had reached the kitchen: the rail stops where the order got to, and
// the stages it genuinely completed stay 'done' rather than being repainted as failures.
let cancelled = OrderProgressBuilder.steps(status: "cancelled", events: [
    ev("placed", "28 Jul, 6:00 PM"), ev("on-hold", "28 Jul, 6:05 PM"),
    ev("processing", "28 Jul, 6:10 PM"), ev("cancelled", "28 Jul, 6:30 PM"),
])
check(cancelled.count == 4, "cancelled after cooking → 3 reached nodes + terminal", "\(cancelled.count)")
check(Array(labels(cancelled).dropLast()) == ["done", "done", "done"], "completed stages stay done")
check(cancelled.last?.isTerminal == true, "the appended node is the terminal one")
check(cancelled.last?.title == "Order Cancelled", "terminal node takes the status title", cancelled.last?.title ?? "nil")
check(cancelled.last?.timestamp == "28 Jul, 6:30 PM", "terminal node takes its own timestamp", cancelled.last?.timestamp ?? "nil")

let recurring = OrderProgressBuilder.steps(status: "processing", events: [
    ev("processing", "28 Jul, 6:10 PM"), ev("processing", "28 Jul, 7:00 PM"),
])
check(recurring[2].timestamp == "28 Jul, 6:10 PM",
      "a stage recorded twice keeps the earlier time", recurring[2].timestamp ?? "nil")

// The pre-deploy reality — the endpoint 404s, so this is what ships today.
let bare = OrderProgressBuilder.steps(status: "processing", events: [])
check(bare.count == 4, "no history → still 4 nodes", "\(bare.count)")
check(labels(bare) == ["done", "done", "current", "upcoming"], "no history → states still derive from status")
check(bare.allSatisfy { $0.timestamp == nil }, "no history → no timestamps invented")

// ── The fallback timeline ─────────────────────────────────────────────────────
// 08:00 UTC is 6:00 PM in Sydney in July. See orderTimelineStamp for why it parses as UTC.
let live = Order(status: "processing", dateCreated: "2026-07-28T08:00:00", dateModified: "2026-07-28T08:10:00")
let fallback = OrderProgressBuilder.fallbackEvents(for: live)
check(fallback.count == 2, "fallback yields placed + current", "\(fallback.count)")
check(fallback.first?.status == "placed", "fallback's first event is placed")
check(fallback.last?.status == "processing", "fallback's second event is the current status")
check(fallback.first?.displayTime == "28 Jul, 6:00 PM",
      "fallback formats date_created for display", fallback.first?.displayTime ?? "nil")

let unpaid = Order(status: "placed", dateCreated: "2026-07-28T08:00:00", dateModified: "2026-07-28T08:00:00")
check(OrderProgressBuilder.fallbackEvents(for: unpaid).count == 1,
      "an order still at placed is not listed twice")

// Order.empty uses "" for both dates.
let blank = Order(status: "processing", dateCreated: "", dateModified: "")
check(OrderProgressBuilder.fallbackEvents(for: blank).isEmpty, "empty dates yield no events")

print(fails == 0 ? "\n  ALL PASS" : "\n  \(fails) FAILURE(S)")
exit(fails == 0 ? 0 : 1)
SWIFT
    TRINH_RESOURCES="$SRC/Resources" run_suite "order status presentation" "$d"
}

# ── Suite: OrderStatusHistory decoding ─────────────────────────────────────────
# Wire format for GET /me/orders/{id}/history. Worth more than the usual decode suite: the
# endpoint is deployed by hand, so the first real payload will arrive on customers' devices
# with nothing between it and the screen.
suite_order_history_decode() {
    local d="$WORK/orderhistory"; mkdir -p "$d"
    cp "$SRC/View/Model/OrderStatusHistoryModel.swift" "$d/" || exit 2
    cat > "$d/main.swift" <<'SWIFT'
import Foundation

var fails = 0
func check(_ ok: Bool, _ what: String, _ detail: String = "") {
    print("  \(ok ? "✓" : "✗") \(what)\(detail.isEmpty ? "" : "  → \(detail)")")
    if !ok { fails += 1 }
}
func decode(_ json: String) -> OrderStatusHistory? {
    try? JSONDecoder().decode(OrderStatusHistory.self, from: Data(json.utf8))
}

// A payload shaped as trinh_app_get_my_order_history emits it: `at` site-local, `at_gmt` UTC.
let payload = #"""
{"order_id":1234,"status":"processing","history":[
 {"status":"placed","at":"2026-07-28T18:00:00","at_gmt":"2026-07-28T08:00:00"},
 {"status":"on-hold","at":"2026-07-28T18:05:00","at_gmt":"2026-07-28T08:05:00"},
 {"status":"processing","at":"2026-07-28T18:10:00","at_gmt":"2026-07-28T08:10:00"}]}
"""#
if let h = decode(payload) {
    check(h.orderID == 1234, "order_id maps to orderID", "\(h.orderID)")
    check(h.status == "processing", "status decodes", h.status)
    check(h.history.count == 3, "every entry decodes", "\(h.history.count)")
    // at_gmt (08:00 UTC) is 6:00 PM Sydney. Preferring `at` would parse an already-local
    // 18:00 as UTC and print "29 Jul, 4:00 AM" — the bug this assertion exists for.
    check(h.timelineEvents.first?.displayTime == "28 Jul, 6:00 PM",
          "at_gmt is preferred over at", h.timelineEvents.first?.displayTime ?? "nil")
} else { check(false, "the plugin's payload decodes") }

// A server older than the at_gmt field must still decode: failing the whole response would
// blank the rail instead of degrading it by a timezone offset.
if let h = decode(#"{"order_id":1,"status":"completed","history":[{"status":"placed","at":"2026-07-28T08:00:00"}]}"#) {
    check(h.history.first?.atGMT == nil, "absent at_gmt decodes as nil")
    check(h.timelineEvents.first?.displayTime == "28 Jul, 6:00 PM",
          "absent at_gmt falls back to at", h.timelineEvents.first?.displayTime ?? "nil")
} else { check(false, "an entry without at_gmt decodes") }

// An order with no recorded transitions is a legitimate response, not an error.
if let h = decode(#"{"order_id":1,"status":"pending","history":[]}"#) {
    check(h.timelineEvents.isEmpty, "empty history yields no events")
} else { check(false, "empty history decodes") }

// A timestamp the formatter cannot read degrades to no time, rather than trapping.
if let h = decode(#"{"order_id":1,"status":"completed","history":[{"status":"placed","at":"not-a-date"}]}"#) {
    check(h.timelineEvents.first?.displayTime == nil, "unparseable timestamp → nil, no crash")
} else { check(false, "an entry with a bad timestamp still decodes") }

// `at` is required. Losing it should fail the response outright — HistoryServices turns that
// into an empty history and the rail falls back — not yield a dateless entry.
check(decode(#"{"order_id":1,"status":"completed","history":[{"status":"placed"}]}"#) == nil,
      "an entry with no `at` must not decode")
check(decode(#"{"orderID":1,"status":"completed","history":[]}"#) == nil,
      "camelCase orderID must not decode")

// Sydney is UTC+10 in July and UTC+11 in January. The rail must not be an hour out for half
// the year, which a fixed offset would make it.
check("2026-07-15T08:00:00".orderTimelineStamp == "15 Jul, 6:00 PM",
      "July renders in AEST (UTC+10)", "2026-07-15T08:00:00".orderTimelineStamp ?? "nil")
check("2026-01-15T08:00:00".orderTimelineStamp == "15 Jan, 7:00 PM",
      "January renders in AEDT (UTC+11)", "2026-01-15T08:00:00".orderTimelineStamp ?? "nil")

print(fails == 0 ? "\n  ALL PASS" : "\n  \(fails) FAILURE(S)")
exit(fails == 0 ? 0 : 1)
SWIFT
    run_suite "OrderStatusHistory decoding" "$d"
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

suite_notification_decode
suite_order_status_presentation
suite_order_history_decode
suite_discount
suite_points_decode

printf '\n%s────────────────────────────%s\n' "$BOLD" "$OFF"
if [[ $SUITES_FAILED -eq 0 ]]; then
    printf '%sall %s suite(s) passed%s\n' "$GREEN" "$SUITES_RUN" "$OFF"
    exit 0
fi
printf '%s%s of %s suite(s) failed%s\n' "$RED" "$SUITES_FAILED" "$SUITES_RUN" "$OFF"
exit 1

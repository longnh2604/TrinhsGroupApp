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

# ── Suite: order line items ─────────────────────────────────────────────────────
# LineItem sits inside Order, which backs the whole Orders tab, so decoding here has to be
# forgiving: a plugin's exotic line-item meta must cost us one label, never the customer's
# order history. Also pins the add-on/note split, which is pure key convention and therefore
# invisible to the compiler.
suite_order_line_items() {
    local d="$WORK/orderitems"; mkdir -p "$d"
    cp "$SRC/View/Model/OrderModel.swift" \
       "$SRC/View/Model/BillingModel.swift" \
       "$SRC/View/Model/ShippingModel.swift" "$d/" || exit 2
    python3 - "$SRC" "$d" <<'PY' || exit 2
import sys
S, d = sys.argv[1], sys.argv[2]

def extract(path, decl, out):
    """Pull one top-level declaration out by brace matching, so a rename fails loudly here
    instead of silently testing nothing."""
    src = open(path).read().split('\n')
    try:
        s = next(i for i, l in enumerate(src) if l.startswith(decl))
    except StopIteration:
        sys.exit(f"{decl} not found in {path} — did it move or get renamed?")
    depth = 0
    for i in range(s, len(src)):
        depth += src[i].count('{') - src[i].count('}')
        if depth == 0 and i > s:
            open(out, 'w').write('import Foundation\n\n' + '\n'.join(src[s:i + 1]) + '\n')
            return
    sys.exit(f"unbalanced braces reading {decl} from {path}")

extract(f'{S}/Utility/Constant.swift', 'enum AnyCodableValue', f'{d}/anycodable.swift')
extract(f'{S}/View/Model/ProductModel.swift', 'struct ProductMetaData', f'{d}/meta.swift')
PY
    cat > "$d/fixture.swift" <<'SWIFT'
import Foundation

// The response shape trinh_app_create_my_order returns. Billing and Shipping are spelled out
// in full because both models declare their fields non-optional — an empty object throws.
let BILLING = #"{"first_name":"Long","last_name":"N","country":"AU","address_1":"1 Main St","city":"Gisborne","postcode":"3437","state":"VIC","email":"a@b.com","phone":"0400"}"#
let SHIPPING = #"{"first_name":"Long","last_name":"N","country":"AU","address_1":"1 Main St","city":"Gisborne","postcode":"3437","state":"VIC"}"#

func orderJSON(lineItems: String, feeLines: String = "[]",
               discountTotal: String = "0.00", total: String = "30.87") -> String {
    """
    {"id":1,"number":"1234","status":"on-hold","date_created":"2026-07-29T08:00:00",
     "date_modified":"2026-07-29T08:00:00","discount_total":"\(discountTotal)","total":"\(total)",
     "customer_note":"","billing":\(BILLING),"shipping":\(SHIPPING),
     "payment_method_title":"Card","line_items":\(lineItems),
     "shipping_lines":[],"fee_lines":\(feeLines)}
    """
}

func decodeOrder(_ json: String) -> Order? {
    try? JSONDecoder().decode(Order.self, from: Data(json.utf8))
}
SWIFT
    cat > "$d/main.swift" <<'SWIFT'
import Foundation

var fails = 0
func check(_ ok: Bool, _ what: String, _ detail: String = "") {
    print("  \(ok ? "✓" : "✗") \(what)\(detail.isEmpty ? "" : "  → \(detail)")")
    if !ok { fails += 1 }
}

// ── Add-ons and notes ───────────────────────────────────────────────────────────
let withMeta = #"""
[{"id":9,"name":"Pho Bo","product_id":5,"quantity":2,"subtotal":"24.00","total":"24.00","price":12.0,
  "meta_data":[{"id":1,"key":"Extra beef","value":"3"},
               {"id":2,"key":"Extra chilli","value":"0"},
               {"id":3,"key":"_note","value":"no coriander"},
               {"id":4,"key":"_reduced_stock","value":"2"}]}]
"""#
if let item = decodeOrder(orderJSON(lineItems: withMeta))?.lineItems.first {
    check(item.meta_data.count == 4, "every meta entry decodes", "\(item.meta_data.count)")
    check(item.addOns.map(\.key) == ["Extra beef", "Extra chilli"],
          "addOns keeps customer-facing keys, in order",
          item.addOns.map(\.key).joined(separator: ", "))
    check(!item.addOns.contains { $0.key.hasPrefix("_") },
          "addOns excludes every underscore-prefixed key")
    check(item.note == "no coriander", "note reads _note", item.note ?? "nil")
} else { check(false, "a line item with meta_data decodes") }

// Woo omits meta_data entirely on a product with no add-ons.
let noMeta = #"[{"id":9,"name":"Spring Rolls","product_id":6,"quantity":1,"subtotal":"8.50","total":"8.50","price":8.5}]"#
if let item = decodeOrder(orderJSON(lineItems: noMeta))?.lineItems.first {
    check(item.meta_data.isEmpty, "absent meta_data decodes as empty")
    check(item.addOns.isEmpty, "no meta → no addOns")
    check(item.note == nil, "no meta → no note")
} else { check(false, "a line item with no meta_data key decodes") }

// A blank note must read as absent, not draw an empty pair of quotes on the card.
let blankNote = #"[{"id":9,"name":"Pho","product_id":5,"quantity":1,"subtotal":"12.00","total":"12.00","price":12.0,"meta_data":[{"id":1,"key":"_note","value":"   "}]}]"#
if let item = decodeOrder(orderJSON(lineItems: blankNote))?.lineItems.first {
    check(item.note == nil, "a whitespace-only note reads as absent", item.note ?? "nil")
} else { check(false, "a line item with a blank note decodes") }

// Another plugin's array-valued meta: AnyCodableValue degrades it to .null, so the ORDER has
// to survive. A throw here would blank the customer's order history.
let exoticMeta = #"[{"id":9,"name":"Pho","product_id":5,"quantity":1,"subtotal":"12.00","total":"12.00","price":12.0,"meta_data":[{"id":1,"key":"Bundle","value":[{"x":1}]},{"id":2,"key":"_note","value":"ok"}]}]"#
if let order = decodeOrder(orderJSON(lineItems: exoticMeta)) {
    check(order.lineItems.count == 1, "an array-valued meta does not fail the order")
    check(order.lineItems[0].note == "ok", "a sibling note still reads",
          order.lineItems[0].note ?? "nil")
} else { check(false, "an order carrying array-valued meta still decodes") }

// The `try?` guard's real job. AnyCodableValue never throws, so an array-valued *value* does
// not exercise it — a non-array meta_data, or an entry missing its required key, is what does.
let metaNotAnArray = #"[{"id":9,"name":"Pho","product_id":5,"quantity":1,"subtotal":"12.00","total":"12.00","price":12.0,"meta_data":{"key":"Extra beef","value":"3"}}]"#
if let order = decodeOrder(orderJSON(lineItems: metaNotAnArray)) {
    check(order.lineItems.count == 1, "meta_data as an object does not fail the order")
    check(order.lineItems[0].meta_data.isEmpty, "undecodable meta_data degrades to empty",
          "\(order.lineItems[0].meta_data.count)")
} else { check(false, "an order whose meta_data is not an array still decodes") }

// A meta entry missing the required `key`.
let metaMissingKey = #"[{"id":9,"name":"Pho","product_id":5,"quantity":1,"subtotal":"12.00","total":"12.00","price":12.0,"meta_data":[{"id":1,"value":"3"}]}]"#
if let order = decodeOrder(orderJSON(lineItems: metaMissingKey)) {
    check(order.lineItems[0].meta_data.isEmpty, "a keyless meta entry degrades to empty",
          "\(order.lineItems[0].meta_data.count)")
} else { check(false, "an order with a keyless meta entry still decodes") }

// ── Add-on labels ──────────────────────────────────────────────────────────────
// Bug A: the card used to render `addOns.map(\.key)`, which on a web order printed the
// group label ("Addition") instead of what the customer picked ("Extra Beef (+$3.00)").
// Every meta_data shape below is verbatim from a live order — the earlier fixtures in this
// suite only carried the app shape, which is why they passed while the bug was live.

func labels(_ lineItems: String) -> [String] {
    decodeOrder(orderJSON(lineItems: lineItems))?.lineItems.first?.addOnLabels ?? []
}
func checkLabels(_ got: [String], _ want: [String], _ what: String) {
    check(got == want, what, got == want ? "" : "got \(got)")
}

// Order 11584 — a ticked checkbox group repeats its key once per chosen option. The
// _ywapo_meta_data sibling is YITH's own bookkeeping and must never reach the customer.
let yithCheckbox = #"""
[{"id":9,"name":"21. Chicken and Rare Beef Pho","product_id":5,"quantity":2,"subtotal":"57.60","total":"57.60","price":28.8,
  "meta_data":[{"id":1,"key":"Addition","value":"Extra Beef (+$3.00)"},
               {"id":2,"key":"Addition","value":"Extra Chicken (+$3.00)"},
               {"id":3,"key":"Addition","value":"Extra Vegies (+$3.00)"},
               {"id":4,"key":"_ywapo_meta_data","value":"[{\"4-0\":{\"display_label\":\"Addition\"}}]"}]}]
"""#
checkLabels(labels(yithCheckbox),
            ["Addition: Extra Beef (+$3.00), Extra Chicken (+$3.00), Extra Vegies (+$3.00)"],
            "a repeated checkbox key collapses to one group, values in order")
if let item = decodeOrder(orderJSON(lineItems: yithCheckbox))?.lineItems.first {
    check(!item.addOnLabels.contains { $0.contains("ywapo") },
          "YITH's _ywapo_meta_data never renders")
} else { check(false, "the YITH checkbox order decodes") }

// Order 11616 — radio groups whose labels are the only thing telling the phos apart,
// alongside a two-option checkbox group.
let yithRadios = #"""
[{"id":9,"name":"Family Share Box","product_id":7,"quantity":1,"subtotal":"69.90","total":"69.90","price":69.9,
  "meta_data":[{"id":1,"key":"1st Pho","value":"Beef"},
               {"id":2,"key":"2nd Pho","value":"Chicken"},
               {"id":3,"key":"4 Fresh Rice Paper Rolls","value":"Prawn"},
               {"id":4,"key":"Addition","value":"10 Chicken Wings + 1 Large Fries"},
               {"id":5,"key":"Addition","value":"6 Crispy Wontons"}]}]
"""#
checkLabels(labels(yithRadios),
            ["1st Pho: Beef", "2nd Pho: Chicken", "4 Fresh Rice Paper Rolls: Prawn",
             "Addition: 10 Chicken Wings + 1 Large Fries, 6 Crispy Wontons"],
            "each radio group keeps its own label")

// Order 11587 — two slots share the label "1 Pho" and both hold Chicken. Deduplicating
// would silently drop a pho the customer paid for. Empty values are options YITH stored
// with no display value, where the key itself is the choice.
let yithDupsAndEmpties = #"""
[{"id":9,"name":"Family Share Box","product_id":7,"quantity":1,"subtotal":"69.90","total":"69.90","price":69.9,
  "meta_data":[{"id":1,"key":"1 Pho","value":"Chicken"},
               {"id":2,"key":"1 Pho","value":"Chicken"},
               {"id":3,"key":"4 Fresh Rice Paper Rolls","value":"Chicken"},
               {"id":4,"key":"10 Chicken Wings","value":""},
               {"id":5,"key":"1 Large Fries","value":""},
               {"id":6,"key":"6 Crispy Wontons","value":""}]}]
"""#
checkLabels(labels(yithDupsAndEmpties),
            ["1 Pho: Chicken, Chicken", "4 Fresh Rice Paper Rolls: Chicken",
             "10 Chicken Wings", "1 Large Fries", "6 Crispy Wontons"],
            "a repeated choice is kept, and an empty value falls back to its key")

// The app path, built by ProductDetailsCard.AddToCartButton: key is the choice, value is
// the price. Rendering the value would show a charge the app path never bills.
checkLabels(labels(withMeta), ["Extra beef", "Extra chilli"],
            "an app-shape price value is dropped, leaving the choice")

let numericForms = #"[{"id":9,"name":"Pho","product_id":5,"quantity":1,"subtotal":"12.00","total":"12.00","price":12.0,"meta_data":[{"id":1,"key":"Extra beef","value":"3.00"},{"id":2,"key":"Extra chilli","value":"0"},{"id":3,"key":"Sauce","value":" 2.5 "},{"id":4,"key":"Herbs","value":4}]}]"#
checkLabels(labels(numericForms), ["Extra beef", "Extra chilli", "Sauce", "Herbs"],
            "a decimal, a zero, a padded and a JSON-number price are all dropped")

// AnyCodableValue degrades an array to .null, whose stringValue is "".
checkLabels(labels(exoticMeta), ["Bundle"], "an undecodable value falls back to its key")

let groupWithBlank = #"[{"id":9,"name":"Pho","product_id":5,"quantity":1,"subtotal":"12.00","total":"12.00","price":12.0,"meta_data":[{"id":1,"key":"Addition","value":""},{"id":2,"key":"Addition","value":"Meat (+$3.00)"}]}]"#
checkLabels(labels(groupWithBlank), ["Addition: Meat (+$3.00)"],
            "a blank sibling does not add an empty choice to its group")

checkLabels(labels(noMeta), [], "no add-ons means no labels")

// ── Fee lines and reconciliation ───────────────────────────────────────────────
// The app's 5% arrives as a negative fee_line, not as discount_total. Reading discountTotal
// for it renders $0.00, which is the bug these assertions exist to prevent coming back.
let twoItems = #"[{"id":9,"name":"Pho Bo","product_id":5,"quantity":2,"subtotal":"24.00","total":"24.00","price":12.0},{"id":10,"name":"Spring Rolls","product_id":6,"quantity":1,"subtotal":"8.50","total":"8.50","price":8.5}]"#
let appFee = #"[{"name":"Discount 5%","total":"-1.63"}]"#

if let o = decodeOrder(orderJSON(lineItems: twoItems, feeLines: appFee)) {
    check(o.fees.count == 1, "fee_lines decodes", "\(o.fees.count)")
    check(o.fees.first?.name == "Discount 5%", "the server's own label is carried through",
          o.fees.first?.name ?? "nil")
    check(o.fees.first?.amount == -1.63, "a negative fee total parses",
          "\(o.fees.first?.amount ?? 0)")
    check(abs(o.subtotal - 32.50) < 0.001, "subtotal sums the line items", "\(o.subtotal)")
    // The whole point of the change: what the card prints has to add up to what was charged.
    let printed = o.subtotal + o.fees.reduce(0) { $0 + $1.amount } - o.discount
    check(abs(printed - (Double(o.total) ?? 0)) < 0.001,
          "subtotal + fees − discount == total", "\(printed) vs \(o.total)")
} else { check(false, "an order with fee_lines decodes") }

// A voucher stacks on top: discount_total non-zero alongside the app fee.
if let o = decodeOrder(orderJSON(lineItems: twoItems, feeLines: appFee,
                                 discountTotal: "5.00", total: "25.87")) {
    let printed = o.subtotal + o.fees.reduce(0) { $0 + $1.amount } - o.discount
    check(abs(printed - 25.87) < 0.001, "reconciles with a voucher too", "\(printed)")
} else { check(false, "an order with a voucher decodes") }

// The plugin only adds fee_lines when the discount is non-zero, so absence is normal and
// must not fail the order.
if let o = decodeOrder(orderJSON(lineItems: twoItems, total: "32.50")) {
    check(o.fees.isEmpty, "absent fee_lines reads as no fees")
} else { check(false, "an order with no fee_lines decodes") }

// orderJSON always emits a fee_lines key, so it cannot express the case that actually
// matters: the plugin omits the key entirely on an undiscounted order. An empty array
// decodes the same whether feeLines is optional or not, so only a genuinely absent key
// exercises the optionality that keeps the Orders tab from going empty.
let noFeeKey = """
{"id":1,"number":"1234","status":"on-hold","date_created":"2026-07-29T08:00:00",
 "date_modified":"2026-07-29T08:00:00","discount_total":"0.00","total":"32.50",
 "customer_note":"","billing":\(BILLING),"shipping":\(SHIPPING),
 "payment_method_title":"Card","line_items":\(twoItems),"shipping_lines":[]}
"""
if let o = decodeOrder(noFeeKey) {
    check(o.fees.isEmpty, "an order with no fee_lines key at all still decodes")
} else { check(false, "an order with no fee_lines key at all still decodes") }

// ── A voucher makes line subtotal and total diverge ────────────────────────────
// Every other fixture here has subtotal == total, so nothing distinguished them. Order.subtotal
// must sum the PRE-coupon line figure: the voucher is already shown as its own Discount row, and
// summing the post-coupon `total` instead would subtract it twice — once inside the item rows and
// again below them.
let voucherItem = #"[{"id":9,"name":"Pho Bo","product_id":5,"quantity":2,"subtotal":"24.00","total":"19.00","price":9.5}]"#
let preCouponFee = #"[{"name":"Discount 5%","total":"-1.20"}]"#
if let o = decodeOrder(orderJSON(lineItems: voucherItem, feeLines: preCouponFee,
                                 discountTotal: "5.00", total: "17.80")) {
    check(o.lineItems[0].subtotal != o.lineItems[0].total,
          "a voucher makes line subtotal and total differ",
          "\(o.lineItems[0].subtotal) vs \(o.lineItems[0].total)")
    check(abs(o.subtotal - 24.00) < 0.001,
          "Order.subtotal sums the pre-coupon line subtotal", "\(o.subtotal)")
    let printed = o.subtotal + o.fees.reduce(0) { $0 + $1.amount } - o.discount
    check(abs(printed - 17.80) < 0.001,
          "the card still reconciles with a voucher on the line", "\(printed)")
} else { check(false, "an order with a coupon-discounted line decodes") }

print(fails == 0 ? "\n  ALL PASS" : "\n  \(fails) FAILURE(S)")
exit(fails == 0 ? 0 : 1)
SWIFT
    run_suite "order line items" "$d"
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

# ── Suite: YITH add-on selection ────────────────────────────────────────────────
# AddOnModel stands between the customer's taps and the `yith_wapo` map that actually buys the
# add-ons, and every rule in it fails quietly. A wrong submit key charges nothing — that was
# order 11690's missing $5.00. A `select` treated as multi-select sends two answers to a
# one-answer group. A required check that counts conditional groups refuses baskets the website
# accepts. The file imports nothing but Foundation, so the real one compiles as-is.
suite_addon_selection() {
    local d="$WORK/addon"; mkdir -p "$d"
    cp "$SRC/View/Model/AddOnModel.swift" "$d/subject.swift"
    cat > "$d/main.swift" <<'SWIFT'
import Foundation
var fails = 0
func check(_ ok: Bool, _ what: String, _ detail: String = "") {
    print("  \(ok ? "✓" : "✗") \(what)\(detail.isEmpty ? "" : "  → \(detail)")")
    if !ok { fails += 1 }
}

let decoder = JSONDecoder()

// Family Trio (11381) and 13. Crispy Pork BanhMi (4486), in the shape
// GET /products/<id>/addons returns — two select groups keyed by addon id, a checkbox group
// keyed addon-option, and money as a formatted string.
let payload = #"""
{"product_id":11381,"addons":[
 {"addon_id":28,"type":"select","title":"1st Pho","description":"","required":true,
  "selection_type":"single","conditional":false,"min":null,"max":null,"options":[
   {"option_id":"0","label":"Chicken","price":"0.00","price_type":"fixed","price_method":"free","submit_key":"28","submit_value":"0"},
   {"option_id":"1","label":"Beef","price":"0.00","price_type":"fixed","price_method":"free","submit_key":"28","submit_value":"1"}]},
 {"addon_id":30,"type":"checkbox","title":"Addition","description":"Pick your sides","required":true,
  "selection_type":"multiple","conditional":false,"min":null,"max":2,"options":[
   {"option_id":"0","label":"2 Fresh Rice Paper Rolls","price":"0.00","price_type":"fixed","price_method":"free","submit_key":"30-0","submit_value":"1"},
   {"option_id":"1","label":"5 Chicken Wings + Small Fries","price":"0.00","price_type":"fixed","price_method":"free","submit_key":"30-1","submit_value":"1"}]},
 {"addon_id":2,"type":"checkbox","title":"BanhMi Addition","description":"","required":false,
  "selection_type":"multiple","conditional":false,"min":null,"max":null,"options":[
   {"option_id":"0","label":"Add Meat","price":"3.00","price_type":"fixed","price_method":"increase","submit_key":"2-0","submit_value":"1"},
   {"option_id":"1","label":"Add Tofu","price":"2.00","price_type":"fixed","price_method":"increase","submit_key":"2-1","submit_value":"1"},
   {"option_id":"2","label":"No Chili","price":"0.00","price_type":"fixed","price_method":"free","submit_key":"2-2","submit_value":"1"}]}]}
"""#

guard let response = try? decoder.decode(AddOnGroupsResponse.self, from: Data(payload.utf8)) else {
    print("  ✗ the real payload must decode"); exit(1)
}
check(response.productId == 11381 && response.addons.count == 3,
      "live payload decodes", "\(response.addons.count) groups")

let pho = response.addons[0]
let addition = response.addons[1]
let banhMi = response.addons[2]

// select and radio take one answer; checkbox takes several. Getting this wrong sends a
// one-answer group two values.
check(!pho.allowsMultiple, "select takes one answer")
check(addition.allowsMultiple, "checkbox takes several")
check(!AddOnGroup(addonId: 9, type: "checkbox", title: "x", selectionType: "single",
                  options: []).allowsMultiple,
      "checkbox pinned to single by YITH's own setting takes one answer")
check(!AddOnGroup(addonId: 9, type: "radio", title: "x", options: []).allowsMultiple,
      "radio takes one answer")

// The submit pair is the whole point of the endpoint: select carries the choice in the value,
// checkbox keys both halves and carries "1".
check(pho.options[1].submitKey == "28" && pho.options[1].submitValue == "1",
      "select submits <addon_id> = <option_id>")
check(addition.options[0].submitKey == "30-0" && addition.options[0].submitValue == "1",
      "checkbox submits <addon_id>-<option_id> = 1")

// Money arrives as a string, and may arrive as a number.
check(banhMi.options[0].price == 3.0, "string price \"3.00\" → 3.0")
let numericPrice = #"{"option_id":"0","label":"x","price":3,"submit_key":"7","submit_value":"0"}"#
check((try? decoder.decode(AddOnOption.self, from: Data(numericPrice.utf8)))?.price == 3.0,
      "JSON-number price 3 → 3.0")

// Tolerance: a group that loses an optional field still decodes, because losing the array
// would leave a required dish impossible to order at all.
let sparse = #"{"addon_id":5,"type":"radio","options":[]}"#
check((try? decoder.decode(AddOnGroup.self, from: Data(sparse.utf8)))?.addonId == 5,
      "group missing every optional field still decodes")
// But an option with no submit pair is useless and must not masquerade as orderable.
let noPair = #"{"option_id":"0","label":"Add Meat","price":"3.00"}"#
check((try? decoder.decode(AddOnOption.self, from: Data(noPair.utf8))) == nil,
      "option without a submit key must NOT decode")

// displayPrice exists so the screen never prints a percentage as dollars.
check(banhMi.options[0].displayPrice == 3.0, "increase shows +3.0")
check(pho.options[0].displayPrice == nil, "free option shows no price")
check(AddOnOption(optionId: "0", label: "x", price: 10, priceType: "percent",
                  priceMethod: "increase", submitKey: "7", submitValue: "0").displayPrice == nil,
      "percent option shows no dollar price")
check(AddOnOption(optionId: "0", label: "x", price: 2, priceMethod: "decrease",
                  submitKey: "7", submitValue: "0").displayPrice == -2.0,
      "decrease shows a negative")

// Toggling. A one-answer group replaces, a multi-answer group accumulates, and tapping the
// chosen option again clears it so an optional choice can be undone.
var selection = AddOnSelection()
selection.toggle(group: pho, option: pho.options[0])
selection.toggle(group: pho, option: pho.options[1])
check(selection.chosenCount(group: pho) == 1 && selection.isChosen(group: pho, option: pho.options[1]),
      "second answer replaces the first in a one-answer group")
selection.toggle(group: banhMi, option: banhMi.options[0])
selection.toggle(group: banhMi, option: banhMi.options[1])
check(selection.chosenCount(group: banhMi) == 2, "a multi-answer group accumulates")
selection.toggle(group: banhMi, option: banhMi.options[1])
check(selection.chosenCount(group: banhMi) == 1, "tapping a chosen option clears it")
check(selection.chosenLabel(group: pho) == "Beef", "the chosen label reads back for the menu")

// The exact map that goes out as yith_wapo, and what it adds for display.
selection.toggle(group: addition, option: addition.options[0])
let choices = selection.choices(in: response.addons)
check(choices.submitPairs == ["28": "1", "30-0": "1", "2-0": "1"],
      "yith_wapo map", "\(choices.submitPairs.sorted { $0.key < $1.key })")
check(choices.displayTotal == 3.0, "display total adds only the priced option")

// Required groups. Order 11690's Family Trio reached the kitchen with no pho, so this is the
// check that has to hold.
check(AddOnSelection().missingRequired(in: response.addons)?.addonId == 28,
      "an untouched required group is reported")
check(selection.missingRequired(in: response.addons) == nil,
      "a fully answered basket reports nothing missing")
let conditionalRequired = AddOnGroup(addonId: 40, type: "radio", title: "Sauce",
                                     required: true, conditional: true, options: [])
check(AddOnSelection().missingRequired(in: [conditionalRequired]) == nil,
      "a conditional required group is never demanded")

// min/max counts options, and an untouched optional group is not 'too few'.
var ranged = AddOnSelection()
check(ranged.outOfRange(in: [addition]) == nil, "untouched group with a max is in range")
ranged.toggle(group: addition, option: addition.options[0])
ranged.toggle(group: addition, option: addition.options[1])
check(ranged.outOfRange(in: [addition]) == nil, "at the max is in range")
let tightMax = AddOnGroup(addonId: 30, type: "checkbox", title: "Addition",
                          selectionType: "multiple", max: 1, options: addition.options)
check(ranged.outOfRange(in: [tightMax])?.addonId == 30, "over the max is reported")
let needsTwo = AddOnGroup(addonId: 30, type: "checkbox", title: "Addition",
                          selectionType: "multiple", min: 2, options: addition.options)
check(AddOnSelection().outOfRange(in: [needsTwo]) == nil, "an untouched group is not below its min")
var one = AddOnSelection()
one.toggle(group: needsTwo, option: needsTwo.options[0])
check(one.outOfRange(in: [needsTwo])?.addonId == 30, "one of a required two is reported")

print(fails == 0 ? "\n  ALL PASS" : "\n  \(fails) FAILURE(S)")
exit(fails == 0 ? 0 : 1)
SWIFT
    run_suite "YITH add-on selection" "$d"
}

suite_notification_decode
suite_addon_selection
suite_order_line_items
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

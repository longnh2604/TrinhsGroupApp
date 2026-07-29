# Order Received Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> Design spec: `docs/superpowers/specs/2026-07-29-order-received-redesign-design.md`

**Goal:** Show the customer the items they just bought on the post-checkout confirmation
screen, and make the money on both order screens reconcile with what was actually charged.

**Architecture:** Three shared views move to `Helpers/` and are used by both the confirmation
screen and the Orders-tab detail screen, so one order reads identically in both places:
`OrderDetailCard` (already exists, currently buried), `OrderLineItemRow` (new, replaces two
divergent per-screen item views) and `OrderPaymentSummaryCard` (new, replaces two divergent
money views). `LineItem` gains `meta_data` so a row can show add-ons and the customer's note;
`Order` gains `fee_lines` so the discount stops being guessed from the total.

**Tech Stack:** Swift 5, SwiftUI, Combine, CocoaPods, Lottie. WooCommerce REST +
`trinh-app/v1`.

## Global Constraints

- iOS deployment target **16.6**. No iOS 17 API. `.onChange(of:perform:)`, not the
  `initial:` form.
- **There is no XCTest target.** Automated tests go in `scripts/run-logic-checks.sh`, which
  compiles real source with `swiftc`. Do not add a test target.
- `project.pbxproj` is `objectVersion = 55` with no synchronized groups — every new Swift file
  needs a manual PBXBuildFile + PBXFileReference + group child + Sources entry (4 each), and
  every deleted file needs those 4 removed.
- **No new localized strings.** Reuse `L10n.OrderReceived.items`,
  `L10n.OrderReceived.discount`, `L10n.Profile.paymentSummary`, `L10n.Common.email`,
  `L10n.Common.subtotal`, `L10n.Common.total`. `en.lproj` is the only localization.
- **Add-on rows show names only, never a price.** The server never charges for add-ons
  (`trinh-app-api.php:276-306` prices every line from the catalog and treats add-on meta as
  text). A surcharge printed here would reconcile with nothing in the card below it.
- The app must not assume the discount rate. Fee rows render the server's own `name` and
  `total`.
- Never commit `Secrets.plist`. Never `git add -A` — stage only the files each step names.
- Build command used throughout:
  ```bash
  xcodebuild build -workspace TrinhsGroup.xcworkspace -scheme TrinhsGroup \
    -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -configuration Debug \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 \
    | grep -E "error:|^\*\* BUILD"
  ```
- `scripts/run-logic-checks.sh` currently has **5** suites and exits 0. It must still exit 0
  after every task.

### Deviation from the spec, deliberate

The spec said to modify `HistoryOrderDetailPaymentView` and `OrderReceivedPricesView`
separately. Both would then hold an identical copy of the `row()` money helper plus identical
fee-line rendering. This plan instead extracts one `OrderPaymentSummaryCard` used by both and
deletes the two, which is the same decision the spec already made for the item row. Net less
code, and the two screens cannot drift.

---

### Task 1: `LineItem.meta_data`, `addOns`, `note`

The highest-risk change here: `LineItem` sits inside `Order`, which backs the whole Orders
tab. A decode throw would empty a customer's order history rather than drop one label.

**Files:**
- Modify: `TrinhsGroup/View/Model/OrderModel.swift:75-101` (the `LineItem` struct)
- Modify: `scripts/run-logic-checks.sh` (add a suite)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `LineItem.meta_data: [ProductMetaData]` — stored, defaults to `[]`
  - `LineItem.addOns: [ProductMetaData]` — computed; customer-facing meta only
  - `LineItem.note: String?` — computed; the `_note` value, `nil` when blank

- [ ] **Step 1: Write the failing suite**

Add this function to `scripts/run-logic-checks.sh`, immediately **before** the
`suite_order_status_presentation` definition:

```bash
# ── Suite: order line items ────────────────────────────────────────────────────
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

// ── Add-ons and notes ──────────────────────────────────────────────────────────
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

print(fails == 0 ? "\n  ALL PASS" : "\n  \(fails) FAILURE(S)")
exit(fails == 0 ? 0 : 1)
SWIFT
    run_suite "order line items" "$d"
}
```

Then register it by changing the invocation block near the bottom of the file from:

```bash
suite_notification_decode
suite_order_status_presentation
```

to:

```bash
suite_notification_decode
suite_order_line_items
suite_order_status_presentation
```

- [ ] **Step 2: Run the suite to verify it fails**

Run: `./scripts/run-logic-checks.sh`

Expected: the `order line items` suite fails to compile with
`value of type 'LineItem' has no member 'meta_data'` (and `addOns`, `note`). The other five
suites still pass.

- [ ] **Step 3: Implement**

In `TrinhsGroup/View/Model/OrderModel.swift`, replace the whole `LineItem` struct with:

```swift
struct LineItem: Codable, Identifiable {
    var id: Int
    var name: String
    var productId: Int
    var quantity: Int
    var subtotal: String
    var total: String
    var price: Double
    /// Add-on selections and the customer's note, exactly as the app sent them at checkout.
    /// Snake-cased to match `ProductOrder.meta_data`, the outbound model it mirrors.
    var meta_data: [ProductMetaData] = []

    private enum CodingKeys: String, CodingKey {
        case id, name
        case productId = "product_id"
        case quantity, subtotal, total, price
        case meta_data
    }

    static var `default`: LineItem {
        LineItem(
            id: 0,
            name: "",
            productId: 0,
            quantity: 0,
            subtotal: "0",
            total: "0",
            price: 0
        )
    }
}

// In an extension, not in the struct body, so the memberwise initialiser survives —
// `LineItem.default` and the previews call it.
extension LineItem {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id        = try container.decode(Int.self, forKey: .id)
        name      = try container.decode(String.self, forKey: .name)
        productId = try container.decode(Int.self, forKey: .productId)
        quantity  = try container.decode(Int.self, forKey: .quantity)
        subtotal  = try container.decode(String.self, forKey: .subtotal)
        total     = try container.decode(String.self, forKey: .total)
        price     = try container.decode(Double.self, forKey: .price)
        // `try?` on purpose. Swift's synthesised decoder ignores default values and throws on
        // a missing key, and Woo omits meta_data on plain products. Beyond that, this model is
        // nested inside Order: a line of add-on labels is not worth failing a customer's whole
        // order history over.
        meta_data = (try? container.decodeIfPresent([ProductMetaData].self, forKey: .meta_data)) ?? []
    }

    /// Add-on selections, customer-facing only.
    ///
    /// WooCommerce's internal line-item meta is underscore-prefixed (`_note`,
    /// `_reduced_stock`) and must never render as something the customer chose.
    var addOns: [ProductMetaData] {
        meta_data.filter { !$0.key.hasPrefix("_") }
    }

    /// The customer's free-text note for this line.
    ///
    /// Blank reads as absent so the card does not draw an empty pair of quotes.
    var note: String? {
        guard let raw = meta_data.first(where: { $0.key == "_note" })?.value.stringValue,
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return raw
    }
}
```

- [ ] **Step 4: Run the suite to verify it passes**

Run: `./scripts/run-logic-checks.sh`
Expected: `all 6 suite(s) passed`, exit 0.

- [ ] **Step 5: Mutation-test the new assertions**

A green suite proves nothing until it has been seen to fail. For each mutation: apply, run,
confirm the named assertion goes red, then `git checkout -- TrinhsGroup/View/Model/OrderModel.swift`.

| Mutation | Assertion that must go red |
|---|---|
| `addOns` filter → `meta_data.filter { true }` | `addOns excludes every underscore-prefixed key` |
| `note` key `"_note"` → `"note"` | `note reads _note` |
| drop the `trimmingCharacters` guard from `note` | `a whitespace-only note reads as absent` |
| `try?` → `try` on the `meta_data` line | `undecodable meta_data degrades to empty` |

`AnyCodableValue` never throws — it degrades arrays and objects to `.null` — so an
array-valued *value* does not exercise the `try?` guard. A non-array `meta_data` or an entry
missing its `key` is what makes `[ProductMetaData]` decoding throw, which is why the last two
assertions exist.

Confirm `./scripts/run-logic-checks.sh` exits 0 again after the last restore.

- [ ] **Step 6: Build**

Run the build command from Global Constraints.
Expected: `** BUILD SUCCEEDED **`. No call site breaks — `meta_data` is last and defaulted.

- [ ] **Step 7: Commit**

```bash
git add TrinhsGroup/View/Model/OrderModel.swift scripts/run-logic-checks.sh
git commit -m "feat(orders): decode per-item add-ons and notes on LineItem"
```

---

### Task 2: `FeeLine` and `Order.feeLines`

**Files:**
- Modify: `TrinhsGroup/View/Model/OrderModel.swift` (`Order` properties, `CodingKeys`,
  `Order.default`, and a new `FeeLine` struct)
- Modify: `scripts/run-logic-checks.sh` (extend `suite_order_line_items`)

**Interfaces:**
- Consumes: the fixture helpers `orderJSON(lineItems:feeLines:discountTotal:total:)` and
  `decodeOrder(_:)` from Task 1's suite.
- Produces:
  - `struct FeeLine { var name: String; var total: String; var amount: Double }` —
    `amount` is `Double(total) ?? 0`, negative for a discount
  - `Order.feeLines: [FeeLine]?` — wire-level, optional because Woo omits the key entirely
  - `Order.fees: [FeeLine]` — computed, `feeLines ?? []`; **use this at every call site**

- [ ] **Step 1: Write the failing assertions**

In `scripts/run-logic-checks.sh`, inside `suite_order_line_items`'s `main.swift` heredoc,
insert this immediately **before** the closing `print(fails == 0 ? ...)` line:

```swift
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
```

- [ ] **Step 2: Run to verify it fails**

Run: `./scripts/run-logic-checks.sh`
Expected: `order line items` fails to compile with `value of type 'Order' has no member 'fees'`.

- [ ] **Step 3: Implement**

In `TrinhsGroup/View/Model/OrderModel.swift`, add `feeLines` to the `Order` stored properties,
immediately after `var shippingLines: [ShippingLine]`:

```swift
    /// Order-level fees. The app's 5% discount arrives here as a negative line, never as
    /// `discount_total`, which carries voucher discounts only.
    ///
    /// Optional because the plugin adds `fee_lines` only when the discount is non-zero, and
    /// Swift's synthesised decoder throws on a missing key for a non-optional property.
    var feeLines: [FeeLine]?
```

Add to `Order`'s `CodingKeys`, after `case shippingLines = "shipping_lines"`:

```swift
        case feeLines = "fee_lines"
```

Add `feeLines: nil` to `Order.default`, after `shippingLines: []`:

```swift
            shippingLines: [],
            feeLines: nil,
```

Add the accessor next to the existing `discount` convenience, so the pair reads together:

```swift
    /// Fees, or none. Prefer this over `feeLines` at call sites.
    var fees: [FeeLine] {
        feeLines ?? []
    }
```

Add the new struct immediately after `struct ShippingLine`:

```swift
struct FeeLine: Codable {
    var name: String
    var total: String

    /// Negative for a discount, which is how the app's 5% is applied.
    var amount: Double {
        Double(total) ?? 0
    }

    static var `default`: FeeLine {
        FeeLine(name: "", total: "0")
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `./scripts/run-logic-checks.sh`
Expected: `all 6 suite(s) passed`, exit 0.

- [ ] **Step 5: Mutation-test**

| Mutation | Assertion that must go red |
|---|---|
| `amount` → `abs(Double(total) ?? 0)` | `a negative fee total parses` |
| `fees` → `[]` | `fee_lines decodes` |
| `var feeLines: [FeeLine]?` → `var feeLines: [FeeLine]` (non-optional), **and** `Order.default`'s `feeLines: nil` → `feeLines: []` so it still compiles | `an order with no fee_lines key at all still decodes` |

`orderJSON` always emits a `fee_lines` key, so proving the optionality needs a payload that
omits it outright — hence the raw literal.

Restore with `git checkout -- TrinhsGroup/View/Model/OrderModel.swift` after each, and confirm
the script exits 0 at the end.

- [ ] **Step 6: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add TrinhsGroup/View/Model/OrderModel.swift scripts/run-logic-checks.sh
git commit -m "feat(orders): decode fee_lines so the app discount stops being guessed"
```

---

### Task 3: Move `OrderDetailCard` into `Helpers/`

Pure relocation, no behaviour change. Its own task because it is the gate that the two later
screens can both see it.

**Files:**
- Create: `TrinhsGroup/Helpers/OrderDetailCard.swift`
- Modify: `TrinhsGroup/View/Profile/HistoryOrderDetailView.swift:113-142` (delete the struct)
- Modify: `TrinhsGroup.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: nothing.
- Produces: `OrderDetailCard(title: String, icon: String? = nil) { content }` — unchanged
  signature, now visible to every screen rather than buried in one.

- [ ] **Step 1: Create the new file**

Create `TrinhsGroup/Helpers/OrderDetailCard.swift`:

```swift
//
//  OrderDetailCard.swift
//  TrinhsGroup
//
//  The white rounded section used by every order card, on both the confirmation screen and
//  the order history detail screen. Lived inside HistoryOrderDetailView.swift while only one
//  screen used it.
//

import SwiftUI

struct OrderDetailCard<Content: View>: View {

    let title: String
    var icon: String? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "98A2B3"))
                }
                Text(title)
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 11))
                    .foregroundColor(Color(hex: "98A2B3"))
                    .tracking(0.8)
                Spacer(minLength: 0)
            }

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}
```

- [ ] **Step 2: Delete the original**

In `TrinhsGroup/View/Profile/HistoryOrderDetailView.swift`, delete the entire
`struct OrderDetailCard<Content: View>: View { … }` declaration (lines 113-142, ending with the
`}` immediately before the blank line preceding `private struct CancelOrderButton`). Leave
`CancelOrderButton` and everything else untouched.

- [ ] **Step 3: Register in the project file**

Add `OrderDetailCard.swift` to `TrinhsGroup.xcodeproj/project.pbxproj` with all four entries,
copying the shape of an existing `Helpers/` file such as `LoadingView.swift`:
PBXBuildFile, PBXFileReference, the `Helpers` group's `children` array, and the
`PBXSourcesBuildPhase` `files` array.

- [ ] **Step 4: Verify exactly one definition survives**

```bash
grep -rn "struct OrderDetailCard" --include="*.swift" .
```
Expected: exactly one hit, in `TrinhsGroup/Helpers/OrderDetailCard.swift`.

- [ ] **Step 5: Build both configurations**

Run the build command, then the same command with `-configuration Release`.
Expected: `** BUILD SUCCEEDED **` twice. A duplicate-symbol error here means Step 2 did not
delete the original; a not-found error means Step 3's pbxproj entries are incomplete.

- [ ] **Step 6: Commit**

```bash
git add TrinhsGroup/Helpers/OrderDetailCard.swift \
        TrinhsGroup/View/Profile/HistoryOrderDetailView.swift \
        TrinhsGroup.xcodeproj/project.pbxproj
git commit -m "refactor(orders): move OrderDetailCard out of the history screen"
```

---

### Task 4: Shared `OrderLineItemRow`

**Files:**
- Create: `TrinhsGroup/Helpers/OrderLineItemRow.swift`
- Modify: `TrinhsGroup/View/Profile/HistoryOrderItemsView.swift:20`
- Delete: `TrinhsGroup/View/Profile/HistoryOrderProductItemView.swift`
- Delete: `TrinhsGroup/View/OrderReceived/OrderReceivedProductItemView.swift`
- Modify: `TrinhsGroup.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `LineItem.addOns` and `LineItem.note` from Task 1.
- Produces: `OrderLineItemRow(item: LineItem)` — one purchased line. Task 7 uses it.

- [ ] **Step 1: Create the shared row**

Create `TrinhsGroup/Helpers/OrderLineItemRow.swift`:

```swift
//
//  OrderLineItemRow.swift
//  TrinhsGroup
//
//  One purchased line, shared by the confirmation screen and the order history detail screen
//  so the same order reads identically in both places.
//

import SwiftUI

struct OrderLineItemRow: View {

    var item: LineItem = LineItem.default

    /// Indent for the secondary lines, so add-ons and the note hang under the product name
    /// rather than under the quantity chip. 30 (chip minWidth) + 12 (stack spacing).
    private let textInset: CGFloat = 42

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                // Quantity as a chip — clearer than "2 X $12.00" run together, and it lets the
                // money column line up down the card.
                Text("\(item.quantity)×")
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 12))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .frame(minWidth: 30)
                    .padding(.vertical, 5)
                    .background(Color(hex: "F2F4F7"))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(item.name)
                    .font(.custom(Constants.AppFont.regularFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 3)

                Spacer(minLength: 8)

                // WooCommerce's `total` is the line total after any discount, which is what the
                // payment summary adds up. Multiplying price × quantity here would disagree
                // with it on a discounted line.
                Text(getPriceAndCurrencySymbol(
                    price: Double(item.total) ?? (item.price * Double(item.quantity)),
                    currency: "$",
                    currencyPosition: "left"
                ))
                    .font(.custom(Constants.AppFont.semiBoldFont, size: 14))
                    .foregroundColor(Constants.AppColor.primaryBlack)
                    .padding(.top, 3)
            }

            // Names only, never a price. The server prices every line from the catalog and
            // treats add-on meta as text, so it never charges for these — a "+$3.00" here
            // would reconcile with nothing in the payment card below.
            if !item.addOns.isEmpty {
                Text(item.addOns.map(\.key).joined(separator: " · "))
                    .font(.custom(Constants.AppFont.regularFont, size: 11))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, textInset)
            }

            if let note = item.note {
                Text("“\(note)”")
                    .font(.custom(Constants.AppFont.regularFont, size: 12))
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, textInset)
            }
        }
    }
}

struct OrderLineItemRow_Previews: PreviewProvider {
    static var previews: some View {
        OrderLineItemRow(item: LineItem.default)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
```

- [ ] **Step 2: Point the history screen at it**

In `TrinhsGroup/View/Profile/HistoryOrderItemsView.swift`, change line 20 from:

```swift
                        HistoryOrderProductItemView(productOrder: item)
```

to:

```swift
                        OrderLineItemRow(item: item)
```

- [ ] **Step 3: Delete the two superseded views**

```bash
git rm TrinhsGroup/View/Profile/HistoryOrderProductItemView.swift \
       TrinhsGroup/View/OrderReceived/OrderReceivedProductItemView.swift
```

`OrderReceivedProductItemView` was already dead — it was typed for `ProductOrder`, which is why
the confirmation screen's item list was commented out.

- [ ] **Step 4: Update the project file**

Add `OrderLineItemRow.swift`'s four entries. Remove all four entries each for
`HistoryOrderProductItemView.swift` and `OrderReceivedProductItemView.swift`.

- [ ] **Step 5: Verify no references survive**

```bash
grep -rn "HistoryOrderProductItemView\|OrderReceivedProductItemView" \
     --include="*.swift" --include="*.pbxproj" .
```
Expected: no output.

- [ ] **Step 6: Build both configurations**

Debug and Release. Expected: `** BUILD SUCCEEDED **` twice.

- [ ] **Step 7: Check the history screen still reads correctly**

Run the app, Orders tab, open an order that has add-ons or a note.
Expected: the rows look as before, now with add-on names and the note underneath. This is the
intended by-product of sharing the row.

- [ ] **Step 8: Commit**

```bash
git add TrinhsGroup/Helpers/OrderLineItemRow.swift \
        TrinhsGroup/View/Profile/HistoryOrderItemsView.swift \
        TrinhsGroup.xcodeproj/project.pbxproj
git commit -m "refactor(orders): one shared line item row for both order screens"
```

---

### Task 5: Shared `OrderPaymentSummaryCard`

Replaces two divergent money views with one. This is the task that makes both screens
reconcile.

**Files:**
- Create: `TrinhsGroup/Helpers/OrderPaymentSummaryCard.swift`
- Modify: `TrinhsGroup/View/Profile/HistoryOrderDetailView.swift` (swap the payment view)
- Delete: `TrinhsGroup/View/Profile/HistoryOrderDetailPaymentView.swift`
- Delete: `TrinhsGroup/View/OrderReceived/OrderReceivedPricesView.swift`
- Modify: `TrinhsGroup.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `Order.fees` and `FeeLine.amount` from Task 2; `OrderDetailCard` from Task 3.
- Produces: `OrderPaymentSummaryCard(order: Order)`. Task 7 uses it.

- [ ] **Step 1: Create the shared card**

Create `TrinhsGroup/Helpers/OrderPaymentSummaryCard.swift`:

```swift
//
//  OrderPaymentSummaryCard.swift
//  TrinhsGroup
//
//  The money breakdown, shared by the confirmation screen and the order history detail
//  screen. One copy because the two previously disagreed: the confirmation screen
//  reverse-engineered the discount as total / 0.95, and the history screen looked for it in
//  discount_total, where the app discount never appears — so it showed a subtotal and a total
//  with nothing in between to explain the gap.
//

import SwiftUI

struct OrderPaymentSummaryCard: View {

    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.Profile.paymentSummary.localized.uppercased(),
            icon: "creditcard"
        ) {
            VStack(spacing: 9) {
                row(L10n.Common.subtotal.localized, amount: order.subtotal)

                // Each fee carries the server's own label and figure — "Discount 5%", "-1.63".
                // The app deliberately does not know the rate: assuming it was the bug this
                // replaces. Identified by offset because FeeLine has no id and two fees may
                // legitimately share a name.
                ForEach(Array(order.fees.enumerated()), id: \.offset) { _, fee in
                    row(
                        fee.name,
                        amount: fee.amount,
                        tint: fee.amount < 0 ? Color(hex: "57A733") : nil
                    )
                }

                // discount_total is voucher discounts only.
                if order.discount > 0 {
                    row(
                        L10n.OrderReceived.discount.localized,
                        amount: -order.discount,
                        tint: Color(hex: "57A733")
                    )
                }

                Rectangle()
                    .fill(Color(hex: "EDEFF2"))
                    .frame(height: 1)
                    .padding(.vertical, 2)

                row(
                    L10n.Common.total.localized,
                    amount: Double(order.total) ?? 0,
                    emphasised: true
                )

                if !order.paymentMethodTitle.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 10))
                        Text(order.paymentMethodTitle)
                            .font(.custom(Constants.AppFont.regularFont, size: 12))
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(Constants.AppColor.secondaryBlack)
                    .padding(.top, 2)
                }
            }
        }
    }

    /// One money line. A negative `amount` prints as `-$1.23` rather than `$-1.23`.
    private func row(
        _ label: String,
        amount: Double,
        tint: Color? = nil,
        emphasised: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(.custom(
                    emphasised ? Constants.AppFont.semiBoldFont : Constants.AppFont.regularFont,
                    size: emphasised ? 15 : 14
                ))
                .foregroundColor(Constants.AppColor.primaryBlack)

            Spacer()

            Text(
                (amount < 0 ? "-" : "")
                + getPriceAndCurrencySymbol(
                    price: abs(amount),
                    currency: "$",
                    currencyPosition: "left"
                )
            )
                .font(.custom(
                    emphasised ? Constants.AppFont.boldFont : Constants.AppFont.regularFont,
                    size: emphasised ? 16 : 14
                ))
                .foregroundColor(tint ?? Constants.AppColor.primaryBlack)
        }
    }
}

struct OrderPaymentSummaryCard_Previews: PreviewProvider {
    static var previews: some View {
        OrderPaymentSummaryCard(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
```

- [ ] **Step 2: Swap it into the history screen**

In `TrinhsGroup/View/Profile/HistoryOrderDetailView.swift`, change:

```swift
                        HistoryOrderDetailPaymentView(order: liveOrder)
```

to:

```swift
                        OrderPaymentSummaryCard(order: liveOrder)
```

- [ ] **Step 3: Delete the two superseded views**

```bash
git rm TrinhsGroup/View/Profile/HistoryOrderDetailPaymentView.swift \
       TrinhsGroup/View/OrderReceived/OrderReceivedPricesView.swift
```

- [ ] **Step 4: Update the project file**

Add `OrderPaymentSummaryCard.swift`'s four entries; remove all four each for
`HistoryOrderDetailPaymentView.swift` and `OrderReceivedPricesView.swift`.

- [ ] **Step 5: Drop the dead call, then verify no references survive**

`OrderReceivedView.swift` still calls the view just deleted. Remove these three lines from its
body — Task 7 rewrites that body in full, this only keeps the build green:

```swift
                        OrderReceivedPricesView()
                            .padding(.bottom)
                            .environmentObject(mainViewModel)
```

Then:

```bash
grep -rn "HistoryOrderDetailPaymentView\|OrderReceivedPricesView" \
     --include="*.swift" --include="*.pbxproj" .
```
Expected: no output.

- [ ] **Step 6: Build both configurations**

Debug and Release. Expected: `** BUILD SUCCEEDED **` twice.

- [ ] **Step 7: Verify the history screen now reconciles**

Run the app, Orders tab, open an order placed through the app.
Expected: a "Discount 5%" row between Subtotal and Total, and
`Subtotal − Discount 5% = Total`. Before this task that row was absent and the figures could
not be reconciled.

- [ ] **Step 8: Commit**

```bash
git add TrinhsGroup/Helpers/OrderPaymentSummaryCard.swift \
        TrinhsGroup/View/Profile/HistoryOrderDetailView.swift \
        TrinhsGroup/View/OrderReceived/OrderReceivedView.swift \
        TrinhsGroup.xcodeproj/project.pbxproj
git commit -m "fix(orders): render fee lines so both order screens reconcile"
```

---

### Task 6: The confirmation hero

**Files:**
- Modify: `TrinhsGroup/View/OrderReceived/HeaderOrderReceivedView.swift` (whole file)

**Interfaces:**
- Consumes: `OrderStatusPresentation(status:)` and its `lottieName` / `icon` / `tint`;
  `String.orderTimelineStamp` from `OrderStatusHistoryModel.swift`; `LottieView`.
- Produces: `HeaderOrderReceivedView(order: Order)` — **note the new parameter**, it no longer
  reads `MainViewModel` from the environment. Task 7 passes the order in.

- [ ] **Step 1: Rewrite the file**

Replace the entire contents of `TrinhsGroup/View/OrderReceived/HeaderOrderReceivedView.swift`:

```swift
//
//  HeaderOrderReceivedView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct HeaderOrderReceivedView: View {

    var order: Order

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Animation, icon and tint come from OrderStatusPresentation so this screen cannot drift
    /// from the status screen. A freshly created order is `on-hold`, giving Order_onHold.
    private var presentation: OrderStatusPresentation {
        OrderStatusPresentation(status: order.status)
    }

    var body: some View {
        VStack(spacing: 12) {
            badge

            // This screen's own copy, not the status vocabulary: "we have your order" is a
            // different message from "here is where your order is". The single-source-of-truth
            // rule forbids a second status→copy map, which this is not.
            Text(L10n.OrderReceived.title.localizedKey)
                .font(.custom(Constants.AppFont.boldFont, size: 21))
                .foregroundColor(Constants.AppColor.primaryBlack)
                .multilineTextAlignment(.center)

            Text(L10n.OrderReceived.thankYouMessage.localizedKey)
                .font(.custom(Constants.AppFont.regularFont, size: 13))
                .foregroundColor(Constants.AppColor.secondaryBlack)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Absorbed from the old detail row, which showed the order number and date beside
            // a Total whose value was commented out.
            Text(metaLine)
                .font(.custom(Constants.AppFont.regularFont, size: 11))
                .foregroundColor(Color(hex: "98A2B3"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var badge: some View {
        if let lottieName = presentation.lottieName {
            // Same 168x104 box as the status hero: Order_processing is 1.74:1 and a square
            // frame letterboxes these scenes to half height.
            LottieView(filename: lottieName, isStop: reduceMotion)
                .frame(width: 168, height: 104)
        } else {
            ZStack {
                Circle()
                    .fill(presentation.tint.opacity(0.10))
                    .frame(width: 96, height: 96)

                Image(systemName: presentation.icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(presentation.tint)
            }
        }
    }

    private var metaLine: String {
        guard let placed = order.dateCreated.orderTimelineStamp else {
            return "Order #\(order.number)"
        }
        return "Order #\(order.number)  ·  \(placed)"
    }
}

struct HeaderOrderReceivedView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderOrderReceivedView(order: Order.default)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
```

- [ ] **Step 2: Keep the existing call site compiling**

`OrderReceivedView.swift` currently calls `HeaderOrderReceivedView()`. Change it to:

```swift
                        HeaderOrderReceivedView(order: mainViewModel.receivedOrder)
```

Task 7 rewrites that body in full; this step only keeps the build green.

- [ ] **Step 3: Build**

Run the build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Verify on screen**

Place a test order in the app.
Expected: the hero shows the `Order_onHold` animation, "Order Received", the thank-you line,
and `Order #… · <date>`. With Reduce Motion on, the animation is static.

- [ ] **Step 5: Commit**

```bash
git add TrinhsGroup/View/OrderReceived/HeaderOrderReceivedView.swift \
        TrinhsGroup/View/OrderReceived/OrderReceivedView.swift
git commit -m "feat(orders): stage-aware hero on the confirmation screen"
```

---

### Task 7: Items card, contact card, and the screen body

The task that actually fixes the reported problem.

**Files:**
- Modify: `TrinhsGroup/View/OrderReceived/OrderReceivedItemsView.swift` (whole file)
- Modify: `TrinhsGroup/View/OrderReceived/OrderReceivedDetailView.swift` (whole file)
- Modify: `TrinhsGroup/View/OrderReceived/OrderReceivedView.swift` (the `body`)

**Interfaces:**
- Consumes: `OrderLineItemRow(item:)` (Task 4), `OrderPaymentSummaryCard(order:)` (Task 5),
  `HeaderOrderReceivedView(order:)` (Task 6), `OrderDetailCard` (Task 3).
- Produces: nothing consumed later.

- [ ] **Step 1: Rewrite the items card**

Replace the entire contents of `TrinhsGroup/View/OrderReceived/OrderReceivedItemsView.swift`:

```swift
//
//  OrderReceivedItemsView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedItemsView: View {

    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.OrderReceived.items.localized.uppercased(),
            icon: "bag"
        ) {
            VStack(spacing: 0) {
                ForEach(Array(order.lineItems.enumerated()), id: \.element.id) { index, item in
                    OrderLineItemRow(item: item)

                    if index < order.lineItems.count - 1 {
                        Rectangle()
                            .fill(Color(hex: "EDEFF2"))
                            .frame(height: 1)
                            .padding(.vertical, 10)
                    }
                }
            }
        }
    }
}

struct OrderReceivedItemsView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedItemsView(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
```

The `ForEach` this restores is the one that was commented out, now with the right type: the old
line passed `LineItem` values to a view declared for `ProductOrder`.

- [ ] **Step 2: Rewrite the detail view as the contact card**

Replace the entire contents of `TrinhsGroup/View/OrderReceived/OrderReceivedDetailView.swift`:

```swift
//
//  OrderReceivedDetailView.swift
//  TrinhsGroup
//
//  Created by long on 11/07/2022.
//

import SwiftUI

struct OrderReceivedDetailView: View {

    var order: Order

    var body: some View {
        OrderDetailCard(
            title: L10n.Common.email.localized.uppercased(),
            icon: "envelope"
        ) {
            Text(order.billing.email)
                .font(.custom(Constants.AppFont.regularFont, size: 14))
                .foregroundColor(Constants.AppColor.primaryBlack)
        }
    }
}

struct OrderReceivedDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OrderReceivedDetailView(order: Order.default)
            .padding()
            .background(Constants.AppColor.lightGrayColor)
            .previewLayout(.sizeThatFits)
    }
}
```

The order number, date and the commented-out Total are gone from here — the hero carries the
first two, and the payment card carries the total.

- [ ] **Step 3: Rewrite the screen body**

In `TrinhsGroup/View/OrderReceived/OrderReceivedView.swift`, replace `var body: some View { … }`
in full (keep `NavigationBarView()` and the preview as they are):

```swift
    var body: some View {
        ZStack {
            Color.init(hex: "f9f9f9")
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                NavigationBarView()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        HeaderOrderReceivedView(order: mainViewModel.receivedOrder)

                        OrderReceivedItemsView(order: mainViewModel.receivedOrder)

                        OrderPaymentSummaryCard(order: mainViewModel.receivedOrder)

                        OrderReceivedDetailView(order: mainViewModel.receivedOrder)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }
```

The `Spacer()` that pushed everything to the bottom is gone: with an item list the content now
fills the screen, and a spacer above a `ScrollView` fights it.

- [ ] **Step 4: Build both configurations**

Debug and Release. Expected: `** BUILD SUCCEEDED **` twice.

- [ ] **Step 5: Check for orphaned environment injections**

```bash
grep -n "environmentObject" TrinhsGroup/View/OrderReceived/OrderReceivedView.swift
```
Expected: no output. All four children now take `order` directly, so the per-child
`.environmentObject(mainViewModel)` calls are gone. Remove any that remain.

- [ ] **Step 6: Commit**

```bash
git add TrinhsGroup/View/OrderReceived/OrderReceivedItemsView.swift \
        TrinhsGroup/View/OrderReceived/OrderReceivedDetailView.swift \
        TrinhsGroup/View/OrderReceived/OrderReceivedView.swift
git commit -m "feat(orders): show purchased items on the confirmation screen"
```

---

### Task 8: End-to-end verification

No code. The gate that this works against the live server, since none of the presentation is
covered automatically.

**Files:** none.

**Interfaces:** none.

- [ ] **Step 1: Automated checks**

```bash
./scripts/run-logic-checks.sh
```
Expected: `all 6 suite(s) passed`, exit 0.

- [ ] **Step 2: Release build**

Run the build command with `-configuration Release`.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: The reported bug**

Place an order with two or more different products.
Expected: every product appears under ITEMS with its quantity and line total. This is what the
screen could not do before.

- [ ] **Step 4: Add-ons and notes**

Place an order where one item has add-ons and a note, and another has neither.
Expected: add-on names on one line, no `+$` figures anywhere, the note in quotes beneath, and
the plain item shows neither. Confirm the same order in the Orders tab reads identically.

- [ ] **Step 5: Money reconciles**

On the confirmation screen, check `Subtotal − Discount 5% = Total`.
Expected: they agree, and the discount row is labelled with the server's own text.

- [ ] **Step 6: Voucher**

Place an order applying a redeemed voucher.
Expected: a "Discount 5%" row **and** a separate voucher row, and
`Subtotal − 5% − voucher = Total`.

- [ ] **Step 7: Long content**

Order an item with a very long name and a three-plus-line note.
Expected: the name wraps without pushing the price off-screen, the note truncates at three
lines, and the page does not scroll sideways.

- [ ] **Step 8: Reduce Motion**

Turn on Reduce Motion, place an order.
Expected: the hero animation is static, everything else renders normally.

- [ ] **Step 9: Orders-tab regression**

Open several past orders, including one placed before this build.
Expected: items, add-ons, notes and a reconciling payment summary. Nothing crashes and no
order list is empty — the last is the Task 1 decode risk.

---

## Self-Review

**Spec coverage**

| Spec requirement | Task |
|---|---|
| `LineItem.meta_data` with forgiving decode | 1 |
| `addOns` excludes underscore-prefixed keys | 1 |
| `note` reads `_note`, blank as absent | 1 |
| `FeeLine` + `Order.feeLines` / `fees` | 2 |
| `OrderDetailCard` moved to `Helpers/` | 3 |
| Shared `OrderLineItemRow`, both screens | 4 |
| Add-on names without prices | 4 (step 1), verified 8.4 |
| Line total from `total`, fallback `price × quantity` | 4 |
| Fee lines rendered; `÷ 0.95` deleted | 5 |
| Orders tab reconciles | 5, verified 8.5/8.9 |
| Hero reuses `OrderStatusPresentation` | 6 |
| Confirmation copy kept, not status copy | 6 (step 1) |
| Order number + date in the hero meta line | 6 |
| Items card renders `lineItems` | 7 |
| Contact card | 7 |
| Card layout on `f9f9f9` | 7 (step 3) |
| No new localized strings | Global Constraints |
| pbxproj entries for 3 new / 4 deleted files | 3, 4, 5 |
| Test suite, mutation-tested | 1 (steps 1-5), 2 (steps 1-5) |
| Manual verification | 8 |

No spec requirement is unassigned. The spec's "modify both payment views" is satisfied by the
documented deviation in Global Constraints (one shared card replaces both).

**Placeholder scan:** every code step contains complete, runnable content. No TBD, no "add
error handling", no "similar to Task N" — Task 5's `row()` helper is written out in full rather
than referenced from the file it came from, because that file is deleted in the same task.

**Type consistency**
- `LineItem.meta_data` / `addOns` / `note` defined in Task 1, used in Task 4 step 1.
- `Order.fees` (not `feeLines`) is what Task 5 calls; Task 2 defines both and marks `fees` as
  the call-site form.
- `FeeLine.amount` defined Task 2, used Task 5 twice with the same name.
- `OrderLineItemRow(item:)` — defined Task 4, called in Task 4 step 2 and Task 7 step 1 with
  the same label.
- `OrderPaymentSummaryCard(order:)` — defined Task 5, called Task 5 step 2 and Task 7 step 3.
- `HeaderOrderReceivedView(order:)`, `OrderReceivedItemsView(order:)`,
  `OrderReceivedDetailView(order:)` — all switched from `@EnvironmentObject` to an `order`
  parameter in Tasks 6-7, and Task 7 step 5 checks the stale injections are gone.
- `String.orderTimelineStamp` (Task 6) already exists in `OrderStatusHistoryModel.swift:76`.

**Known gap, accepted:** Tasks 3-7 have no automated coverage. There is no XCTest target and
these are SwiftUI views, so Task 8 covers them manually. The pure logic underneath them —
decoding, the add-on/note split, and the reconciliation arithmetic — is covered by Tasks 1-2
and mutation-tested.

**Out of scope, flagged:** the server never charges for add-ons
(`trinh-app-api.php:276-306`). Revenue-affecting, needs its own plan.

# Order Received Screen Redesign — Design

> Post-checkout confirmation (`OrderReceivedView`). Companion to
> `2026-07-28-order-status-redesign-design.md`, whose card system this screen adopts.

## Goal

Show the customer what they just bought. The confirmation screen currently prints a subtotal
and a total with no item list, so the one moment the customer wants to check their order
against what they intended is the one moment the app will not tell them.

Secondary: make the money on both order screens reconcile. Neither of them currently does.

## Why the current screen falls short

The item list is not missing — it is commented out. `OrderReceivedItemsView.swift:20-22`:

```swift
//            ForEach(mainViewModel.receivedOrder.lineItems) { item in
//                OrderReceivedProductItemView(productOrder: item)
//            }
```

It cannot compile as written. `receivedOrder.lineItems` is `[LineItem]`; the item view takes a
`ProductOrder`. Two models describe the same concept — `ProductOrder` is what the app *sends*
at checkout, `LineItem` is what the server *returns* — and the screen was wired to the wrong
one. So the "Items" heading renders above nothing.

The same file pattern repeats twice more on this screen:

- `OrderReceivedDetailView.swift:42-44` — the Total value is commented out, leaving a column
  header with no figure under it.
- `OrderReceivedPricesView.swift:29-32` — the discount line is reverse-engineered from the
  total, `finalTotal / 0.95`, because `fee_lines` is not decoded. Correct only while the rate
  is exactly 5% and no voucher is involved.

## Constraints discovered before designing

- **The data is already in the response.** `Order` decodes `line_items`
  (`OrderModel.swift:38`) and `receivedOrder` is populated from the create-order response
  (`MainViewModel.swift:210-213`). No server change is needed for the item list.
- **`LineItem` carries no `meta_data`**, so neither this screen nor the Orders tab can show
  per-item notes or add-ons today. The app *does* send them at checkout
  (`MainServices.swift:130-141`), so they are on the order and only need decoding.
- **The 5% discount is a negative `fee_line`, not `discount_total`**
  (`trinh-app-api.php:363-371`). `discount_total` carries voucher discounts only. Any design
  that reads `discountTotal` for the app discount will display `$0.00`.
- **`AnyCodableValue` degrades arrays and nested objects to `.null`** rather than throwing
  (`Constant.swift:142-143`), so decoding arbitrary WooCommerce line-item meta is safe.
- **`project.pbxproj` is `objectVersion = 55`** with no synchronized groups — every new Swift
  file needs a manual PBXBuildFile + PBXFileReference + group child + Sources entry.
- **There is no XCTest target.** Automated tests go in `scripts/run-logic-checks.sh`, which
  compiles real source with `swiftc`.
- iOS deployment target **16.6**.
- Never commit `Secrets.plist`. Never `git add -A`.

## Pre-existing bug found in passing (out of scope, flagged not fixed)

**Add-on surcharges are never charged.** The plugin prices every line straight from the
catalog and treats add-on meta as labels only (`trinh-app-api.php:276-306`):

```php
$clean = [ 'product_id' => $product_id, 'quantity' => $quantity ];
// meta_data carries the add-on selections (rice type, spice level…) — text only.
$subtotal += (float) $product->get_price() * $quantity;
```

No `price`, `subtotal` or `total` is ever set. Meanwhile the app adds the surcharge locally —
`ProductDetailsCard.swift:264`, `newPrice += Double(addon.value)` — so the cart shows an
inflated figure the server then ignores. A customer who picks "Extra beef (+$3.00)" is not
charged for it.

**This directly shapes the design:** add-on rows show the add-on *name only*, with no `+$`
figure. Printing a surcharge that reconciles with nothing on a confirmation screen would make
the screen lie about money, which is worse than saying less. Fixing the server pricing is a
revenue-affecting change and belongs in its own task.

## Model changes

All in `OrderModel.swift`, all shared with the Orders tab.

### `LineItem.meta_data`

```swift
var meta_data: [ProductMetaData] = []
```

Decoded through a custom `init(from:)` rather than the synthesized one, so that a malformed
meta array degrades to `[]`:

```swift
meta_data = (try? container.decodeIfPresent([ProductMetaData].self, forKey: .metaData)) ?? []
```

This matters because `LineItem` sits inside `Order`, which backs the whole Orders tab. A throw
here would empty a customer's order history rather than drop one label.

### Derived accessors on `LineItem`

Views stay free of meta-key knowledge:

```swift
/// Add-on selections, customer-facing only. WooCommerce's internal meta is underscore-
/// prefixed (`_reduced_stock`, `_note`) and must not be rendered as an add-on.
var addOns: [ProductMetaData] { meta_data.filter { !$0.key.hasPrefix("_") } }

/// The customer's free-text note for this line.
var note: String? {
    guard let raw = meta_data.first(where: { $0.key == "_note" })?.value.stringValue,
          !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
    return raw
}
```

An empty-string note must read as absent, not as a blank quoted line.

### `FeeLine` and `Order.feeLines`

```swift
struct FeeLine: Codable {
    var name: String     // server-authored, e.g. "Discount 5%"
    var total: String    // e.g. "-1.63"
}

var feeLines: [FeeLine]  // CodingKeys: case feeLines = "fee_lines"
```

The app renders the server's own label and figure. It does not know the discount rate and must
not assume one — that assumption is the bug being removed.

## Shared components

Two views move to `TrinhsGroup/Helpers/`, this project's established home for cross-feature
views (`LoadingView`, `CustomAlertView`, `CheckBoxView` all live there).

### `OrderDetailCard.swift`

Moved verbatim from `HistoryOrderDetailView.swift:113`. Unchanged; it was simply buried inside
one screen's file while now serving two.

### `OrderLineItemRow.swift`

One row, used by both order screens. Replaces `HistoryOrderProductItemView` and the dead
`OrderReceivedProductItemView`.

```
2×   Pho Bo                          $24.00
     Extra beef · Extra chilli
     "no coriander"
```

- Quantity as a chip (`F2F4F7`, 7pt radius) so the money column aligns down the card
- Name at 14pt regular
- Add-on names joined by `·`, 11pt, `secondaryBlack`, no prices — see the flagged bug above
- Note in quotes, 12pt, `secondaryBlack`, `lineLimit(3)`
- Line total from `item.total`, falling back to `price × quantity`

**Consequence, accepted deliberately:** sharing this row gives the Orders tab notes and
add-ons too. The same order should read identically on both screens, and duplicating the row
to avoid the improvement would be the worse trade.

## Screen layout

Nav bar → hero → ITEMS → PAYMENT → CONTACT, on the existing `f9f9f9` background, each section
an `OrderDetailCard`.

```
┌───────────────────────────────────┐
│ ✕                        Checkout │
├───────────────────────────────────┤
│         ( Order_onHold )          │
│        Order Received             │
│   Thank you. Your order has       │
│        been received.             │
│  Order #1234 · 29 Jul, 6:05 PM    │
├───────────────────────────────────┤
│ 🛍  ITEMS                         │
│  2×   Pho Bo             $24.00   │
│       Extra beef                  │
│  ─────────────────────────────    │
│  1×   Spring Rolls        $8.50   │
├───────────────────────────────────┤
│ 💳  PAYMENT                       │
│     Subtotal            $32.50    │
│     Discount 5%         −$1.63    │
│     Total               $30.87    │
├───────────────────────────────────┤
│ ✉️  CONTACT                       │
│     you@email.com                 │
└───────────────────────────────────┘
```

### The hero

`HeaderOrderReceivedView` is rewritten as the hero. It takes its animation and tint from
`OrderStatusPresentation(status: receivedOrder.status)` so it cannot drift from the status
screen — a freshly created order is `on-hold`, giving `Order_onHold`.

Copy stays the existing `L10n.OrderReceived.title` and `thankYouMessage`. The status
presentation's copy is deliberately *not* substituted: "thank you, we have your order" is a
different message from "here is where your order is", and this screen's job is the former. The
one-source-of-truth rule from the status redesign forbids inventing a *second* status→copy
map; it does not require every screen to speak in status terms.

Order number and date move into the hero's meta line. That retires the commented-out Total in
`OrderReceivedDetailView` rather than repairing it, and lets the screen open on reassurance
instead of on admin — the same reasoning as the status screen's hero.

`OrderReceivedDetailView` is left holding only the email, and becomes the CONTACT card.

## Money

```
Subtotal        Order.subtotal          Σ line item subtotals (existing computed property)
<fee name>      each Order.feeLines     server label + figure, e.g. "Discount 5%  −$1.63"
Discount        Order.discountTotal     voucher discounts, rendered only when > 0
Total           Order.total
```

**No new localized strings are needed.** Fee rows carry the server's own `name`. The
`discount_total` row reuses `L10n.OrderReceived.discount` — exactly the string
`HistoryOrderDetailPaymentView.swift:24` already uses for it, so the two screens stay
consistent. Card titles reuse `L10n.OrderReceived.items`, `L10n.Profile.paymentSummary` (the
Orders tab's own payment card title) and `L10n.Common.email`. `en.lproj` is the only
localization in the project.

This reconciles because WooCommerce's `total` is line totals plus fees minus discounts, and
this store has neither shipping nor tax on app orders. Negative amounts print as `−$1.63`, not
`$-1.63`, reusing the `row()` helper already in `HistoryOrderDetailPaymentView`.

The `÷ 0.95` derivation is deleted.

### The Orders tab gets the same fix

`HistoryOrderDetailPaymentView.swift:22` gates its discount row on `order.discount`
(`discount_total`), which is `0.00` for app orders. That screen therefore shows Subtotal
$32.50 and Total $30.87 with **no discount line at all** — figures that cannot be reconciled
by the customer. It gets the same fee-line row. Same root cause, same one-line render.

## Files

**Create (2)**
- `TrinhsGroup/Helpers/OrderDetailCard.swift`
- `TrinhsGroup/Helpers/OrderLineItemRow.swift`

**Modify (10)**
- `TrinhsGroup/View/Model/OrderModel.swift`
- `TrinhsGroup/View/OrderReceived/OrderReceivedView.swift`
- `TrinhsGroup/View/OrderReceived/HeaderOrderReceivedView.swift`
- `TrinhsGroup/View/OrderReceived/OrderReceivedItemsView.swift`
- `TrinhsGroup/View/OrderReceived/OrderReceivedPricesView.swift`
- `TrinhsGroup/View/OrderReceived/OrderReceivedDetailView.swift`
- `TrinhsGroup/View/Profile/HistoryOrderItemsView.swift`
- `TrinhsGroup/View/Profile/HistoryOrderDetailPaymentView.swift`
- `TrinhsGroup/View/Profile/HistoryOrderDetailView.swift` (drop the moved `OrderDetailCard`)
- `TrinhsGroup.xcodeproj/project.pbxproj`

**Delete (2)**
- `TrinhsGroup/View/OrderReceived/OrderReceivedProductItemView.swift` (dead, `ProductOrder`-based)
- `TrinhsGroup/View/Profile/HistoryOrderProductItemView.swift` (superseded by the shared row)

## Testing

A new `suite_order_line_items` in `scripts/run-logic-checks.sh`. `OrderModel.swift` is pure
Foundation, so it compiles standalone after `ProductMetaData` and `AnyCodableValue` are copied
in from `ProductModel.swift` / `Constant.swift`.

- `meta_data` decodes from a realistic `line_items` payload
- `addOns` excludes `_note` and other underscore-prefixed keys; `note` finds `_note`
- an array-valued meta degrades to `.null` without throwing the order away
- a line item with no `meta_data` key at all still decodes, `addOns` empty, `note` nil
- `fee_lines` decodes; a negative `total` parses
- reconciliation: `subtotal + Σ fees − discountTotal == total` on a realistic payload
- line total prefers `total` over `price × quantity`

Every assertion must be mutation-tested: break the source, confirm the suite goes red, restore.

Then `xcodebuild` Debug **and** Release, and a device pass on an order with add-ons, a note, a
voucher, and one with none of them.

## Deliberately not included

- **Fixing add-on pricing server-side.** Revenue-affecting, needs its own testing and deploy.
  Flagged above.
- **Reconciling the cart's inflated price with the server's total.** Same root cause; the cart
  is a different screen.
- **A confirmation-specific Lottie.** No `Order_confirmed.json` exists, and `Order_onHold` is
  semantically right for a just-created order.
- **Touching `ProductOrder`.** It is the correct model for the outbound checkout payload; only
  its misuse on this screen was wrong.

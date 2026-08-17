# YITH add-on parity for the app

**Goal:** an add-on order placed in the app is byte-for-byte the same order as one placed
on the website — same options offered, same meta stored, same money charged.

**Decision (Long, 2026-07-30):** YITH is the single source of truth. The app reads add-on
definitions from YITH and Firestore add-ons are retired. Pricing is computed by YITH
server-side, never replicated in `trinh-app-api.php` or the app.

---

## 1. Why

Order **11690** (app, `created_via=rest-api`, 2026-07-30) against order **11613** (web,
`created_via=checkout`) — same product, `Family Trio` (11381):

| | Family Trio line meta |
|---|---|
| 11613 web | `1st Pho=Chicken`, `2nd Pho=Beef`, `Addition=2 Fresh Rice Paper Rolls`, `Addition=5 Chicken Wings + Small Fries` |
| 11690 app | *(zero entries)* |

That Family Trio reached the kitchen with no pho choice. The same order's
`13. Crispy Pork BanhMi` carried `Add Meat=3` and `Add Tofu=2` on an $11.50 line whose
total was **$11.50** — **$5.00 not charged**.

Root cause: `trinh_app_create_my_order` builds a `$body` array and dispatches it to
`/wc/v3/orders` (`trinh-app-api.php:385`). That path never touches the WooCommerce cart, so
YITH's hooks never fire. Add-on meta is accepted as text only
(`trinh-app-api.php:287-301`) and every line is priced from the catalog
(`$product->get_price()`, line 305).

### The definitions the app cannot currently see

`Family Trio` (11381), read from the rendered product form:

| addon_id | type | title | required | options (`option_id` · price) |
|---|---|---|---|---|
| 28 | `select` | 1st Pho | yes | Chicken `0` · $0 — Beef `1` · $0 |
| 29 | `select` | 2nd Pho | yes | Chicken `0` · $0 — Beef `1` · $0 |
| 30 | `checkbox` | Addition | yes | 2 Fresh Rice Paper Rolls `30-0` · $0 — 5 Chicken Wings + Small Fries `30-1` · $0 |

`13. Crispy Pork BanhMi` (4486):

| addon_id | type | title | options |
|---|---|---|---|
| 2 | `checkbox` | Addition | Add Meat `2-0` · $3 — Add Tofu `2-1` · $2 — No Chili `2-2` · $0 — No Coriander `2-3` · $0 — No Pate `2-4` · $0 |

YITH is a **superset** of the Firestore add-ons for 4486 (same names, same prices, plus
three more), so retiring Firestore loses nothing on this product. **Every other product
with Firestore add-ons still needs this checked before its Firestore entry is deleted.**

### Types in use

`select` (native dropdown), `radio`, `checkbox`. YITH also supports color, label, product,
text, textarea, number, file, date, colorpicker — none currently used.

**In a saved order, `select` and `radio` are indistinguishable**: both store one entry with
`key`=group title, `value`=chosen label. So display code needs no type awareness — the
`addOnLabels` fix in `74ea283` already renders both correctly. This plan is about **input**.

### YITH's submit contract

- `select` / `radio` → `yith_wapo[][<addon_id>]` = `<option_id>`, e.g. `[][28] = "0"`
- `checkbox` → `yith_wapo[][<addon_id>-<option_id>]`, e.g. `[][30-0] = "1"`

Same key shape as `_ywapo_meta_data` (`"4-0"`, `"4-1"`, …).

---

## 2. Feasibility — verified against the plugin source

`wp-content/plugins/yith-woocommerce-product-add-ons/includes/class-yith-wapo-cart.php`:

| Step | Method | Fires on | Produces |
|---|---|---|---|
| 1 | `add_cart_item_data($data, $product_id, $post_data)` (line 335) | callable **directly** — `$post_data` is an explicit 3rd param, no `$_POST` forgery | `$cart_item['yith_wapo_options']` |
| 2 | `add_cart_item($cart_item)` (line 422) | `woocommerce_add_cart_item` | `set_price(base + get_addons_totals_in_cart())` ← **the missing charge** |
| 3 | `add_order_item_meta($item_id, $cart_item, $key)` (line ~470) | `woocommerce_new_order_item` | `display_label`/`display_value` + `_ywapo_meta_data` |

Steps 2 and 3 fire automatically once the item is in a real cart and the order is created
from it. Only step 1 needs an explicit call.

**Not a blocker:** `add_to_cart_addons_validation` reads `$_POST` and would see nothing,
but its loop only runs for non-empty `yith_wapo` and only stock-checks `product`-type
add-ons. Trinh's uses none. `$passed` stays `true`.

**Note on double-firing:** WooCommerce fires `woocommerce_add_cart_item_data` (priority 25)
during `add_to_cart()` with `$post_data = null`, so YITH re-reads an empty `$_POST` and
returns the passed array unchanged. Pre-built `$cart_item_data` survives untouched.

---

## 3. Work

### Phase 1 — read endpoint (WP)

`GET /wp-json/trinh-app/v1/products/<id>/addons`

Reads `wp_yith_wapo_blocks` / `wp_yith_wapo_addons` via `yith_wapo_get_option_info()` and
the plugin's own accessors — **not raw SQL**, so YITH's option schema stays its own
business. Returns per addon: `addon_id`, `type`, `title`, `required`, `description`,
`min`/`max` where set, and per option: `option_id` (in submit-key form), `label`, `price`,
`price_method`.

- Public read (no JWT) — the same data is already in public product-page HTML.
- Cache in a transient keyed by product id, busted on `yith_wapo_save_block` (confirm the
  actual save hook name before relying on it; fall back to a short TTL).

→ verify: response for 11381 matches the table in §1 exactly; for 4486, five options with
prices `3, 2, 0, 0, 0`.

#### Written 2026-07-30, unverified pending deploy

`GET /products/<id>/addons` (public, optional `?variation_id=`). Per group: `addon_id`, `type`,
`title`, `description`, `required`, `selection_type`, `conditional`, `min`, `max`, `options`.
Per option: `option_id`, `label`, `price`, `price_type`, `price_method`, and **`submit_key` +
`submit_value`** — the exact pair to post back. That last part is deliberate: the key shape
depends on the type (select/radio key the group and carry the choice in the value, checkbox keys
both and carries `"1"`), and deriving it in the app would put one rule in two places, which is
the shape of the bug this plan exists to fix. Enumeration is shared with the order path's
required check (`trinh_app_yith_addons_for_product`) so the two cannot disagree.

Three corrections to this phase as written:

- **There is no save hook to bust the cache on.** YITH fires only
  `yith_wapo_before/after_addons`, `_show_options_shortcode`, `_after_add_order_item_meta` and
  `_migrated`. A 5-minute TTL is the honest ceiling on staleness.
- **A transient keyed by product id would leak across roles.** `yith_wapo_get_blocks_by_product`
  filters on login state, roles and membership plans, so the answer is per-customer. The key
  carries that context. It also means a JWT-bearing caller sees exactly the groups the order
  endpoint will validate against, while a guest sees the guest view — each self-consistent.
- **Conditional-logic groups cannot be enforced.** `enable_rules` groups are shown or hidden by
  browser-side rules. They are reported as `conditional: true` and the required check now skips
  them: demanding an answer we cannot know is owed would reject baskets the website accepts.
  If any group at Trinh's actually uses conditional logic, Phase 3 has to handle it.

Also fixed in the Phase 2 code while here: `{"28": "default"}` used to satisfy the required
check while producing nothing. `default` is the unchosen placeholder in a select
(`templates/front/addons/select.php:34`) and YITH writes no meta for it, so it is now dropped
like an empty value — otherwise 11690's pho-less Family Trio comes straight back.

### Phase 2 — write path (WP)

Rework `trinh_app_create_my_order` to go through the cart instead of dispatching a
pre-priced `$body`:

1. `wc_load_cart()` — REST has no cart/session by default.
2. Per incoming item, build `$post_data = ['yith_wapo_product_id' => $pid, 'yith_wapo' => [[ '28' => '0' ], [ '30-0' => '1' ]]]`, then
   `$cart_item_data = YITH_WAPO_Cart::get_instance()->add_cart_item_data([], $pid, $post_data)`.
3. `WC()->cart->add_to_cart($pid, $qty, 0, [], $cart_item_data)` — step 2 of §2 prices it.
4. Reject the request if a `required` addon group has no selection — the website enforces
   this and the app must not be a way around it.
5. Create the order from the cart so `woocommerce_new_order_item` fires and YITH writes the
   display meta.
6. Re-apply what the current endpoint already does: forced `customer_id`, allowlisted
   status, gateway check, billing, pickup meta, the discount `fee_line`, voucher ownership
   check.
7. `WC()->cart->empty_cart()` in a `finally`, so a failed request cannot leak cart state
   into the next one.

→ verify: an app order for 11381 with `[][28]=0, [][29]=1, [][30-0]=1` produces meta
identical to 11613's, and an app order for 4486 with Add Meat + Add Tofu prices the line at
**$16.50**, not $11.50.

#### Written 2026-07-30 — `trinh-app-api` 1.3.0, unverified pending deploy

`php -l` passes and every WooCommerce/YITH signature above was checked against plugin source,
but neither verify step has been run: no DB, no deploy path (open question 2). Structure:
`trinh_app_with_app_cart()` guards the session and builds the cart, then hands it to a
callback — `trinh_app_create_order_from_cart()` or `trinh_app_preview_order_totals()`, so
quoting and charging cannot drift. `trinh_app_validated_line_items()` is shared by both.

Three things this plan had wrong or missing:

- **Step 5 needs `WC_Checkout` specifically.** YITH's `add_order_item_meta` reads
  `WC_Order_Item_Product::$legacy_values`, set in exactly one place in WooCommerce —
  `WC_Checkout::create_order_line_items()` (`class-wc-checkout.php:539`). `wc_create_order()`
  + `add_product()` would fire the hook with nothing for YITH to read.
- **Step 7 was too late to protect the customer's website cart.** `WC_Cart_Session` hooks
  `persistent_cart_update` on `woocommerce_add_to_cart` (`class-wc-cart-session.php:80`), and
  a logged-in JWT user shares that session, so the damage lands on *add*, not on exit.
  Now: park `session['cart']`, filter `woocommerce_persistent_cart_enabled` off, restore in
  `finally`. Also nulls `order_awaiting_payment`, or a stale id from an abandoned web checkout
  would make `create_order()` resume that order instead of opening a new one.
- **Step 4 cannot be enforced unconditionally without breaking shipped binaries.** Old app
  versions send add-ons as `meta_data` text and no `yith_wapo`, so Family Trio's three
  required groups would reject every order on deploy. Enforcement turns on only when a request
  carries at least one `yith_wapo` selection, and then applies to every line in that order so
  a YITH-aware client cannot dodge a group by omitting its key. Tighten once old binaries age
  out.

### Phase 2b — quote endpoint (WP)

`POST /wp-json/trinh-app/v1/me/orders/preview` — same body as order creation minus status,
billing and pickup time; creates nothing. Returns `subtotal`, `discount_total`, `fee_lines`
(the server's own labels, so the 5% row needs no rate in the app) and `total`. Fee totals are
read from `$fee->total`, not `$fee->amount`: WooCommerce clamps a negative fee so it cannot
take an order below zero and writes the clamped figure back (`class-wc-cart-totals.php:323`),
and that is what `create_order_fee_lines()` puts on the order.

This exists because the checkout screen cannot compute either half of its own total any more —
add-on prices come from YITH, the discount from a gateway fee, and neither exists until a cart
does.

→ verify: a quote and the order subsequently placed from the same basket agree on `total`.

### Phase 3 — app (iOS)

1. `AddOnGroup` / `AddOnOption` Codable models + fetch in the product service.
2. Render by type: `select` → picker/menu, `radio` → single-select, `checkbox` → multi.
   Required groups block Add-to-Cart until chosen.
3. Send `yith_wapo`-shaped selections at checkout instead of `ProductMetaData` built from
   Firestore (`ProductDetailsCard.swift:261-266`, `ItemDetailsView.swift:110`).
4. Stop adding add-on prices client-side (`ProductDetailsCard.swift:264` does
   `newPrice += Double(addon.value)` and overwrites `price`/`regular_price`) — the server is
   authoritative once Phase 2 lands.
5. Retire the Firestore add-on read only after per-product parity is confirmed (§1).
6. Show the server's total on the checkout screen from `POST /me/orders/preview` (Phase 2b)
   instead of adding anything up locally. This is also what puts the 5% row back: `8bc7980`
   removed it, and until the app reads the quote it will display a total ~5% above what a
   cash-on-pickup order actually charges. The `fee_lines` read path is already there and
   covered (`FeeLine`, plus the `Discount 5%` and `-1.63` cases in `run-logic-checks.sh`) —
   the checkout screen is the only part that cannot see it.

→ verify: place a real app order for Family Trio; its meta matches a web order for the same
choices. The quote shown at checkout equals the placed order's `total`. Add-on assertions in
`scripts/run-logic-checks.sh` still pass (display is unaffected — `74ea283`).

#### Written 2026-07-30 — builds clean, 29 new assertions passing

`AddOnModel.swift` (`AddOnGroup`, `AddOnOption`, `AddOnChoice`, `AddOnSelection`),
`OrderQuoteModel.swift`, `AddOnGroupsView.swift`; `productAddOns` and `orderQuote` endpoints;
`MainServices.fetchAddOnGroups` / `fetchOrderQuote` over a shared `lineItemsPayload`, so the
quote and the order describe one basket. `xcodebuild` succeeds with no warning in any changed
file, and a new `suite_addon_selection` in `run-logic-checks.sh` compiles the real
`AddOnModel.swift` and pins 29 cases — submit-key shaping per type, string/number prices,
decode tolerance, single-vs-multi toggling, required, conditional and min/max.

- **Selection state is per screen, not shared.** The Firestore add-ons kept `checked` on a
  singleton keyed by *category*, so two dishes in one category shared a set of ticks and the
  fetch handed every dish the same options. `AddOnSelection` is `@State` on the card.
- **`Product.price` is left alone.** `unitPrice` = `price` + chosen add-ons, and it is display
  only. `cartIdentifier` now includes the submit pairs, or a second Family Trio with different
  pho would just increment the first one's quantity.
- **Two display paths had to move with it.** The cart read add-ons out of `meta_data` and its
  unit-price line read `price`; both were only correct while add-ons were being written into
  meta_data and folded into the price. They read `addOnChoices` and `unitPrice` now.
- **`select` renders as a menu, `radio`/`checkbox` as lists**, mirroring the website. Required
  groups disable Add to Cart with the reason shown, rather than a dimmed button and a later
  400 from the server.

Still open from this phase:

- **Item 5 is the live risk.** The app now reads YITH only, so any product where Firestore held
  an option YITH lacks silently loses it. YITH is a superset for 4486; §1's audit of every other
  product is still not done. `FirestoreManager.fetchProductAddOns` and `ProductAddOns` are left
  in place — nothing calls them now, so reverting is a one-line change until that audit lands.
- Pre-existing dead code found while working here, untouched: `ItemDetailsView.swift` is never
  instantiated (it holds the second, older copy of the add-on UI), and `CartView.swift:27` has a
  `return false` short-circuiting the Monday-closed check.

---

## 4. Open questions — need Long's answer

1. ~~**Discount base.**~~ **Resolved 2026-07-30, twice.** First reading was that the 5% had
   been withdrawn outright (`8bc7980` app-side, plus the `fee_lines` block removed from
   `trinh-app-api.php`). That was only half true: what was withdrawn is the app *computing*
   it. The discount itself lives on the website as a **negative gateway fee** on cash on
   pickup — `alg_gateways_fees_value_other_payment = -5`, type `percent`, read by
   `checkout-fees-for-woocommerce`. So there is still no base to decide, but for the opposite
   reason: the plugin decides it, on `WC()->cart->cart_contents_total`
   (`class-alg-wc-checkout-fees.php:941`) — line totals, i.e. **after** add-ons are priced in
   and **after** any voucher. Going through the cart earns the discount back for free, with
   no rate in the app, and only on cash on pickup rather than on every payment method as the
   withdrawn version did.
2. **Deployment.** Phases 1-2 are production PHP on Hostinger. No local DB (port 3306
   closed) and no deploy path from this machine. Needs a staging target, or SFTP, or Long
   deploys by hand.
3. **Per-product parity sweep.** Which products have Firestore add-ons that YITH lacks?
   4486 is clean; the rest are unaudited. Deleting Firestore before this is checked would
   silently drop options.

## 5. Risks

- **`woo-delivery` injects required cart fields.** A cart-based flow may now hit validation
  the dispatch-based flow bypassed. Test a real app order end to end before shipping.
- **Cart in REST is stateful.** `wc_load_cart()` plus a customer session on a stateless
  endpoint is the fiddliest part of Phase 2 — hence the `finally` empty_cart.
- **LiteSpeed cache** must be purged after deploying either phase.
- The rewrite touches money. Every verification step above is a real order compared against
  a real web order, not a unit test.

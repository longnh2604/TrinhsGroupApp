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

→ verify: place a real app order for Family Trio; its meta matches a web order for the same
choices. Add-on assertions in `scripts/run-logic-checks.sh` still pass (display is
unaffected — `74ea283`).

---

## 4. Open questions — need Long's answer

1. ~~**Discount base.**~~ **Resolved 2026-07-30** — the 5% was withdrawn entirely
   (`8bc7980` app-side, plus the `fee_lines` block removed from `trinh-app-api.php`). There
   is no discount base to decide, and Todo 3 is closed with it: `CheckOutView.swift` no
   longer computes a rate. Add-on pricing now flows straight through as full price.
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

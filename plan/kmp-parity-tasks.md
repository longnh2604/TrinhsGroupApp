# KMP (Android) → iOS Parity — Task Board

> Rewritten 2026-08-14 against the real source of truth.
> **Source of truth:** `main` — `origin/features/OrderStatusNotification` was merged into it on
> 2026-08-17 (merge `886de7c`), so main now carries the 118-file live app. Comparisons made
> before that date were against the branch; they still hold.
> **Target:** `kmp/` — `shared/` (KMP) + `androidApp/` (Compose). **Android is the only tested target.**

---

## 1. Method

Read the whole branch tree (17.1k lines of Swift) — `WooCommerceOAuth.swift`, all four services and
ViewModels, the tab shell, checkout, order screens, profile cluster, add-ons, notification store —
and diffed it against `kmp/shared` (30 models, 4 services, 4 ViewModels, 16 test files) and
`kmp/androidApp` (14 Compose screens).

The KMP port was made from a **mid-2026 state of that branch**, not from the old `main`. It got the shape
right — points, vouchers, pickup, popular products, Menu tab, `WooCommerceEndpoint` mirroring
`WooCommerceOAuth.swift` — then the branch moved on by ~40 commits (JWT migration, YITH add-ons,
order status timeline, notification→order navigation, profile redesign, the 5% withdrawal).

**The earlier "Option A" direction is void.** Points, vouchers and pickup are live iOS features;
shipping methods and `woo-tools-app/coupon` codes are not — `ShipMethodModel` and the legacy
`checkCouponCode` are orphans on the branch. The only piece of Option A that survives is the store
URL: KMP points at `trinhsgroup.au`, iOS at `trinhsgroup.com.au`.

## 2. The architectural delta (this drives P0)

iOS moved off "consumer key does everything" onto a custom plugin namespace, and moved pricing to
the server:

| | KMP today | iOS branch |
|---|---|---|
| Credentials | write-capable `ck_`/`cs_` pair embedded in `WooCommerceApi.kt:43`, Basic auth on **every** call | read-only key from untracked `Secrets.plist`, used **only** for catalog reads; everything else uses the signed-in user's JWT |
| Token storage | `multiplatform-settings` (plain prefs) | Keychain, `ThisDeviceOnly`, with JWT `exp` decoding, `.sessionExpired` broadcast and forced re-login |
| Scoping | `/orders?customer={id}`, `/bu/v1/vouchers?user_id={id}` — an id in the URL | `/me/orders`, `/me/vouchers` — the account comes from the JWT, server-side |
| Signup | `POST /wc/v3/customers` with the write key | `POST /trinh-app/v1/register` |
| Pricing | client computes totals, sends prices, adds a 5% `fee_lines` | server prices the cart: `POST /me/orders/preview` returns subtotal, discount, fee lines, total. App sends **no prices at all** |
| The 5% | still applied client-side | withdrawn from the app (`8bc7980`); it is now a negative gateway fee configured on the website |
| Add-ons | Firestore `productAddons` collection, flat checkboxes | YITH via `GET /trinh-app/v1/products/{id}/addons` — groups with required/min/max, single or multi select, submitted as `yith_wapo` pairs |

Endpoint map to port (`shared/.../network/WooCommerceEndpoint.kt`):

```
/wp-json/trinh-app/v1/register                     POST   (no auth)
/wp-json/jwt-auth/v1/token                         POST   (form)
/wp-json/wc/v3/products/categories                 GET    (read-only key)
/wp-json/wc/v3/products?orderby=popularity…        GET    (read-only key)
/wp-json/wc/v3/products?category={id}              GET    (read-only key)
/wp-json/trinh-app/v1/products/{id}/addons         GET    (read-only key)
/wp-json/trinh-app/v1/me                           GET PUT DELETE   (JWT)
/wp-json/trinh-app/v1/me/orders                    GET POST         (JWT)
/wp-json/trinh-app/v1/me/orders/preview            POST             (JWT)
/wp-json/trinh-app/v1/me/orders/{id}/cancel        POST             (JWT)
/wp-json/trinh-app/v1/me/orders/{id}/history       GET              (JWT)
/wp-json/trinh-app/v1/me/orders/{id}/payment-intent GET             (JWT)
/wp-json/trinh-app/v1/me/vouchers                  GET              (JWT)
/wp-json/trinh-app/v1/payment-methods              GET              (JWT)
/wp-json/trinh-app/v1/fcm/register|unregister      POST             (JWT)
/wp-json/bu/v1/me/points                           GET              (JWT)
/wp-json/bu/v1/redeem                              POST             (JWT, no user_id)
/wp-json/wc/v3/customers/{id}/avatar               POST DELETE      (JWT)
```

## 3. Gap matrix

Legend: ✅ matches · ⚠️ partial or stale · ❌ missing · 🗑 delete

### Networking & session

| iOS | KMP | Work |
|---|---|---|
| Read-only key for catalog, JWT for the rest (`WooCommerceOAuth.swift:142`) | ❌ one Basic-auth client with the write secret | Two auth modes; `requiresJWT` per endpoint |
| Store `trinhsgroup.com.au` | ❌ `trinhsgroup.au` | Repoint |
| JWT in Keychain + `exp` decode + auto-logout on 401/403 | ❌ plain settings, no expiry handling | EncryptedSharedPreferences (androidx.security) + expiry check + a session-expired flow |
| `/trinh-app/v1/*` endpoint set (above) | ⚠️ old `/wc/v3` + `/bu/v1?user_id=` shapes | Rewrite `WooCommerceEndpoint` |
| Server-side `/register` | ❌ `POST /wc/v3/customers` | Swap |
| GET cache-busting `_=` param, no-cache headers, one retry on transient errors | ❌ | Add to the Ktor client |

### Checkout & pricing

| iOS | KMP | Work |
|---|---|---|
| `POST /me/orders/preview` drives every figure; re-quoted when payment method or voucher changes | ❌ | `OrderQuote` model + service + re-quote triggers |
| Order payload: no `customer_id`, no `set_paid`, no prices | ⚠️ sends all three | Rewrite `buildOrderJson`, re-pin `OrderCreationPayloadTest` |
| 5% is a server gateway fee | 🗑 client-side `fee_lines` in `MainService.kt` | Delete |
| Fee lines rendered from the server's own labels | ❌ | Render `quote.fees` |
| Pickup date/time (`PickupDateTimeView`, server owns parsing) | ✅ same slots, today only | Rule moved to `DateTimeUtils.availablePickupSlots` 2026-08-22 and pinned; Android used to drop the slot starting exactly now |
| Voucher picker from `/me/vouchers` | ⚠️ right UI, wrong endpoint (`?user_id=`) | Repoint |
| Payment list excludes `woocommerce_payments_*` and `stripe_*` prefixes | ⚠️ only filters `enabled` | Add the prefix filter |
| Stripe: create order → `/me/orders/{id}/payment-intent` → PaymentSheet → refresh points/vouchers → order received; Safari fallback on `paymentURL`; deep-link return | ❌ `StripePresenter` never called | Wire the whole flow |
| Billing gate before submit (`checkUserUpdatedBillInfo`) + token-expiry check | ❌ only `user.id > 0` | Add both |
| Cart blocks checkout on Mondays (Australia/Sydney) | ❌ | Port the gate |

### Products & add-ons

| iOS | KMP | Work |
|---|---|---|
| YITH add-on groups: required, min/max, single/multi, per-option price, `yith_wapo` submit pairs | ❌ Firestore checkboxes | Replace `FirestoreClient.productAddOns` with the endpoint + `AddOnGroup/Option/Choice/Selection` models and validation |
| Per-item special note → `_note` meta | ❌ | Note field on product detail, shown in cart and order screens |
| `ProductCard` + `ProductDetailsCard` | ✅ close enough | Sanity-check against the branch |

### Orders

| iOS | KMP | Work |
|---|---|---|
| Orders as a **tab** (today only) + past orders from Profile | ❌ no orders screen | `MyOrdersScreen` with both filters |
| Order detail + 4-stage progress rail from `/me/orders/{id}/history`, 7 status presentations, Lottie per stage | ❌ | `OrderStatusPresentation` + `OrderProgressBuilder` port (pure logic — test it) |
| Cancel order | ❌ | `/me/orders/{id}/cancel` |
| `fee_lines` decoded on Order; per-item add-ons and notes on `LineItem` | ⚠️ older `Order`/`LineItem` | Extend models + tests |
| Order received: stage-aware hero, shared items card, reconciled fee lines | ⚠️ older screen | Rework against the branch |

### Notifications

| iOS | KMP | Work |
|---|---|---|
| FCM register on login / unregister on logout, tied to JWT | ✅ `PushTokens` + `/fcm/register`\|`unregister` | none |
| `NotificationStore`: persisted history, unread badge, `syncDeliveredNotifications()` | ✅ shared `NotificationStore`, bell badge, `syncTrayNotifications()` | none |
| Tap → order detail, incl. cold launch via `pending_order_id` | ✅ intent extra held until the shell is up | none |
| Push toggle in Profile | 🗑 the iOS toggle is `@State` only — decorative, wired to nothing | don't port |

### Profile

| iOS | KMP | Work |
|---|---|---|
| Avatar: photo picker + camera, multipart upload, remove | ❌ | `/customers/{id}/avatar` POST/DELETE |
| Points balance + redeem chips (≥10, multiples of 10) | ⚠️ balance shown only | Redeem UI + `/bu/v1/redeem` (no `user_id`) |
| My Vouchers (available + history) | ❌ | `MyVouchersScreen` |
| Edit Profile / Edit Address (`PUT /me`) | ❌ dead menu items; `AuthService.updateUser()` is a no-op | Both screens + the PUT |
| Delete account (`DELETE /me`) | ❌ | Add |
| Help & Support, Legal (terms/privacy), app version footer | ❌ | Static |
| Logout | ⚠️ doesn't unregister FCM | Add unregister |

### Shell, Home, Menu, Favorites

| iOS | KMP | Work |
|---|---|---|
| 5 tabs: Home, Menu, **Orders** (raised centre button), Favorites, Profile; cart is an overlay | ⚠️ 4 tabs: Home, Menu, **Cart**, Profile | Restructure; decide whether to keep Cart as a tab |
| Home: 3 bundled event posters + full-screen poster viewer, categories row, popular products | ⚠️ hardcoded promo images, categories, popular products | Port posters + viewer |
| Menu: circular category selector, product cards (search commented out) | ✅ close | Compare visually |
| Favorites tab | ❌ data layer done, no screen | `FavoritesScreen` |
| Splash + session restore | ✅ | none |
| Forgot password | ⚠️ service ready, route is `// TODO` | Wire the screen |

### Not to port (orphans on the branch)

`SettingView`, `ItemDetailsView`, `SaleView`, `DiscountView`, `ImageSliderView`, `OnboardingView`,
`AccountCenterView`, `RewardsCenterView`, Firestore events/add-ons, `ShipMethodModel` + shipping
zones, the legacy `woo-tools-app/coupon` path, the FB Messenger launch link. KMP's own
`FetchAllProducts`-style needs don't arise — there is no Sale/Discount section any more.

---

## 4. TODO plan

### P0 — auth, scoping, pricing ✅ done 2026-08-14

All seven land together: 198 shared tests green, `:androidApp:assembleDebug` builds.
**Before running the app**, put the read-only key in `kmp/local.properties` (gitignored):
`WOO_CONSUMER_KEY=…` / `WOO_CONSUMER_SECRET=…` — the same pair iOS keeps in `Secrets.plist`.
Without it the catalog calls get no credentials and the store returns 401.

| # | Task | Files |
|---|---|---|
| ✅ K-01 | Repoint to `trinhsgroup.com.au`; split credentials: read-only key for catalog reads, JWT for everything else; keys via Gradle property → `BuildConfig`, not constructor defaults | `shared/.../network/WooCommerceApi.kt`, `androidApp/build.gradle.kts`, `di/AppModule.kt` |
| ✅ K-02 | Rewrite `WooCommerceEndpoint` to the `/trinh-app/v1` map in §2, with a `requiresJWT` flag | `WooCommerceEndpoint.kt` + `WooCommerceEndpointTest` |
| ✅ K-03 | JWT lifecycle: store in EncryptedSharedPreferences, decode `exp`, session-expired event, forced re-login, 401/403 handling | `shared/.../storage/KeyValueStore.kt`, `AuthService.kt`, `AuthViewModel.kt` |
| ✅ K-04 | Signup via `/register`; `updateUser` via `PUT /me`; `fetchUser` via `GET /me`; delete account via `DELETE /me` | `AuthService.kt` |
| ✅ K-05 | Order quote: `OrderQuote` model + `POST /me/orders/preview`, re-quoted on payment-method and voucher change | `MainService.kt`, `MainViewModel.kt`, `ui/checkout/` |
| ✅ K-06 | Order payload to the branch's shape (no `customer_id`/`set_paid`/prices); delete the client-side 5% `fee_lines` | `MainService.kt`, `OrderCreationPayloadTest` |
| ✅ K-07 | Vouchers and points via `/me/vouchers`, `/bu/v1/me/points`, `/bu/v1/redeem` (drop every `user_id` argument) | `PointsService.kt`, `PointsViewModel.kt` + tests |

### P1 — the order lifecycle

| # | Task | Files |
|---|---|---|
| ✅ K-08 | Extend `Order`/`LineItem`: `fee_lines`, per-item add-ons, `_note` | `shared/.../model/`, `OrderTest`, `SnapshotParsingTest` |
| ✅ K-09 | Port `OrderStatusPresentation` + `OrderStage` + `OrderProgressBuilder` (pure logic — test directly) | `shared/.../order/` (new), `commonTest` |
| ✅ K-10 | `MyOrdersScreen` (today / past filters, pull-to-refresh) as a tab + from Profile | `ui/orders/`, `MainScreen.kt` |
| ✅ K-11 | Order detail: progress rail from `/me/orders/{id}/history`, items card, payment summary, cancel order | `ui/orders/`, `HistoryService.kt` |
| ✅ K-12 | Rework Order Received around the stage-aware hero + shared items card + fee lines | done 2026-08-21. `ui/orders/OrderCards.kt` holds the hero, items and payment cards; both Order Received and the history detail draw from it, so the two can no longer disagree about the money. The old screen computed its own subtotal from line items and ignored `fees` |
| ✅ K-13 | Stripe: order → payment-intent → PaymentSheet → refresh → received; browser fallback + deep-link return | `ui/checkout/`, `StripePresenter.kt`, `StripeRepository.kt` |

### P2 — add-ons, notifications, profile

| # | Task | Files |
|---|---|---|
| ✅ K-14 | YITH add-on groups replacing Firestore add-ons: models, validation (required/min/max), `yith_wapo` submit pairs | fixed in `42a3e3f`: the mapping moved to `ProductOrder.from(item)` in shared, pinned by `ProductOrderMappingTest`, and `MainService` submits `yith_wapo` |
| ✅ K-15 | Special note per item (`_note`), rendered in cart and order screens | shipped in `42a3e3f` |
| ✅ K-16 | FCM: messaging service, register on login / unregister on logout, persisted `NotificationStore` equivalent, bell + unread badge, tap → order detail (incl. cold launch) | done 2026-08-21. `PushMessagingService` + `PushTokens` (androidApp/firebase), shared `NotificationStore` replaces `NotificationsRepository`, `NotificationsScreen`, `HistoryViewModel.openOrder(orderId)`. Gap: a push the system shows while the app is backgrounded reaches the history through `syncTrayNotifications()` without an order id, so it is not tappable — send `title`/`body` in the push's `data` block to close that |
| ✅ K-17 | Profile: avatar upload/remove, redeem chips, My Vouchers, Edit Profile, Edit Address, push toggle, legal, support, version, delete account | done 2026-08-21. Avatar: `WooCommerceApi.doMultipartUpload` + `AuthService.uploadAvatar`/`removeAvatar`, photo picker and camera in `ui/profile/AvatarPicker.kt` (EXIF-corrected, sampled down, JPEG 85 as iOS). Support/legal/version rows in `ui/profile/LegalDocuments.kt`, same wording as iOS. The push toggle is **not** ported: iOS's is `@State` wired to nothing |
| ✅ K-18 | Billing gate + token-expiry check before submit; Monday-closed gate in cart | token-expiry gate shipped in `42a3e3f`. The Monday gate is **not** ported: `CartView.isMondayInAustralia()` returns `false` before it reaches the weekday check, so iOS never blocks a Monday. Porting it would make Android stricter than the app it mirrors |

### P3 — shell and polish

| # | Task | Files |
|---|---|---|
| ✅ K-19 | 5-tab shell with the raised centre Orders button; cart as overlay | done 2026-08-21. The circle is drawn outside the Scaffold's `bottomBar` because a `NavigationBar` is a Surface and clips anything lifted above it; the centre slot keeps its place in the bar but draws neither icon nor label |
| ✅ K-20 | Home event posters + full-screen poster viewer (Firestore-driven) | `ui/home/` |
| ✅ K-21 | `FavoritesScreen`; `ForgotPasswordScreen` | `ui/favorites/`, `ui/auth/` |
| ✅ K-22 | Lottie order-status animations, app icon/logo, image cache config, localisation | done 2026-08-21. `lottie-compose` + the five `Order_*.json` scenes in `assets/`, driven by the `lottieName` the shared `OrderStatusPresentation` already carried; reduce-motion holds the first frame. Launcher icon is the iOS `AppIcon` art, adaptive at 50dp inside the 108dp canvas so a round mask does not cut "8890", plus a monochrome `ic_notification`. Splash and login now draw `ic_logo` instead of their placeholders. Coil cache was already configured in `TrinhsApp`. **Localisation has nothing to port**: iOS ships `en.lproj` only and has no Vietnamese anywhere — the note in this row was wrong |

---

## 5. Open questions

1. **Read-only consumer key for Android.** iOS keeps it in an untracked `Secrets.plist`
   (`Secrets.example.plist` template, `scripts/rotate-woo-key.sh`). Android needs the same value —
   its own key or the shared one — supplied out of band, never committed. The old `SECURITY_CODE`
   question is closed: that scheme no longer exists.
2. **Does the `trinh-app` plugin allow a second client?** Nothing in the app suggests per-client
   restrictions, but worth confirming with whoever runs the WordPress side before Android starts
   hitting `/trinh-app/v1/*`.
3. **Cart: tab or overlay?** iOS made it an overlay and gave the tab slot to Orders. Compose's cart
   tab is arguably better on Android; parity would drop it. Your call — K-19 assumes we follow iOS.
4. **KMP is chasing a moving branch.** It has drifted ~40 commits in ~3 months. Worth deciding
   whether Android tracks a tagged iOS release rather than branch HEAD.

## 6. Verification

```bash
cd kmp
./gradlew :shared:testDebugUnitTest   # commonTest on the Android target only
./gradlew :androidApp:assembleDebug
```

Extend the existing tests rather than adding suites: `OrderCreationPayloadTest` pins the order JSON
(K-06), `WooCommerceEndpointTest` pins the URL map (K-02), `MainViewModelCartMathTest` pins totals
(K-05), `PointsServiceTest`/`PointsViewModelCanRedeemTest` pin redemption (K-07). K-09 is pure logic
and should get its own test file, mirroring the branch's status-mapping tests.

Manual end-to-end on Android against `trinhsgroup.com.au`: register → login → session survives
restart → browse Menu → product with required add-ons + note → cart (Monday gate) → checkout quote
matches after switching payment method and applying a voucher → pay by card and by cash → order
received → Orders tab → progress rail → cancel → push arrives → tap → order detail → redeem points →
avatar upload → logout unregisters push.

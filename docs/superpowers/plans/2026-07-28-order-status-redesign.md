# Order Status Redesign — Implementation Plan

> Design spec: `docs/superpowers/specs/2026-07-28-order-status-redesign-design.md`

**Goal:** Redesign the order detail screen around a stage-aware, animated status card,
backed by a new endpoint that supplies a real timestamp per stage.

**Architecture:** One presentation type (`OrderStatusPresentation`) owns all status copy,
icons, colours and stage ordering. One view (`OrderProgressCard`) renders hero + stepper
from it. `HistoryViewModel` holds the fetched history and falls back to
`dateCreated`/`dateModified` when it has none.

**Tech stack:** SwiftUI (iOS 16.6 floor), Lottie (already a pod), WooCommerce REST +
custom `trinh-app/v1` namespace, PHP 8.

## Global constraints

- Deployment target **16.6** — no `.symbolEffect`, no `PhaseAnimator`, no iOS 17 API.
- No new pods. Lottie and `Resources/cookLoading.json` already ship.
- `project.pbxproj` is `objectVersion = 55` with no synchronized groups — every new
  Swift file needs a manual PBXBuildFile + PBXFileReference + group entry + Sources entry.
- Never commit `Secrets.plist`. Never `git add -A`.
- The client must render correctly against a server that does **not** have the new
  endpoint (404) — the WP side deploys by hand and will lag the app.
- Format all timeline times from `at_gmt`, never `at`, because
  `toAustraliaDateTime()` parses its input as UTC.
- Terminal statuses (`cancelled`, `refunded`, `failed`) never animate.

---

### Task 1: Server endpoint

**Files:** modify `/Volumes/Untitled/public_html/wp-content/plugins/trinh-app-api/trinh-app-api.php`

- [ ] Register `GET /me/orders/(?P<id>\d+)/history` with `trinh_app_require_auth` and
      `absint` on `id`, mirroring the `/cancel` route's shape.
- [ ] `trinh_app_status_name_map()` — build `[display name => slug]` from
      `wc_get_order_statuses()` (strip the `wc-` prefix), lowercased keys.
- [ ] `trinh_app_parse_transition_note($content, $map)` — match both
      `"Order status changed from X to Y."` and `"Order status set to Y."`, return the
      destination slug or `null`.
- [ ] `trinh_app_order_status_history(WC_Order $order)` — the four construction steps
      from the spec: `placed` anchor, parsed notes, current-status fallback, sort +
      collapse consecutive duplicates.
- [ ] `trinh_app_get_my_order_history(WP_REST_Request $request)` — ownership check
      identical to `trinh_app_cancel_my_order`, then emit `order_id` / `status` /
      `history` with both `at` and `at_gmt`.
- [ ] Bump the plugin header to `Version: 1.1.0`.
- [ ] Verify: `php -l` clean.

### Task 2: `OrderStatusPresentation`

**Files:** create `TrinhsGroup/View/Profile/OrderStatusPresentation.swift`

- [ ] `enum OrderStage: Int, CaseIterable` — `placed`, `received`, `cooking`, `ready`,
      each with a `title`.
- [ ] `struct OrderStatusPresentation` — `title`, `subtitle`, `icon`, `lottieName`,
      `tint`, `reachedStage`, `isTerminal`; `init(status:)` covering the seven slugs plus
      an unknown-slug default.
- [ ] Verify: standalone Swift test asserting the mapping table, that `pending`'s
      `reachedStage == .placed`, and that the three failures are terminal.

### Task 3: History model + data flow

**Files:**
- create `TrinhsGroup/View/Model/OrderStatusHistoryModel.swift`
- modify `TrinhsGroup/Utility/WooCommerceOAuth.swift`, `TrinhsGroup/View/Services/HistoryServices.swift`,
  `TrinhsGroup/View/ViewModel/HistoryViewModel.swift`

- [ ] `OrderStatusEvent` (`status`, `at`, `atGMT`) + `OrderStatusHistory`
      (`orderID`, `status`, `history`), `CodingKeys` for snake_case.
- [ ] `case myOrderHistory(orderID: Int)` in `WooCommerceEndpoint`, added to both
      `urlPath()` and the `requiresJWT == true` list.
- [ ] `HistoryServices.onFetchOrderStatusHistory(orderID:)` publishing through a
      `PassthroughSubject`. A failure publishes an **empty** history rather than routing
      into `errorPublisher`, because a 404 from an undeployed server must not surface an
      alert.
- [ ] `HistoryViewModel.statusHistory` + `loadStatusHistory(orderID:)`.
- [ ] Verify: standalone Swift test decoding a sample payload, and one asserting a
      missing `at_gmt` does not throw.

### Task 4: `OrderProgressCard`

**Files:** create `TrinhsGroup/View/Profile/OrderProgressCard.swift`

- [ ] Hero: tinted circle, Lottie for `processing`, SF Symbol otherwise, halo pulse,
      pop-in for `completed`, title + subtitle.
- [ ] Stepper: four fixed nodes, per-node state (done / current / pending) derived from
      the presentation's `reachedStage`; timestamps from history keyed by stage.
- [ ] Terminal layout: nodes up to the last reached stage, then the terminal node, rail
      grey beyond it.
- [ ] Rail: animated fill on appear; dashed for the unreached remainder.
- [ ] `@Environment(\.accessibilityReduceMotion)` disables every repeating animation.
- [ ] Fallback: when `history` is empty, node 1 takes `order.dateCreated` and the current
      node takes `order.dateModified`.
- [ ] Verify: the stage/timestamp reduction is a pure function tested standalone; visual
      check by build + preview.

### Task 5: Restyle the detail screen

**Files:**
- modify `HistoryOrderDetailView.swift`, `HistoryOrderItemsView.swift`,
  `HistoryOrderDetailPaymentView.swift`, `HistoryOrderNoteView.swift`,
  `HistoryOrderAddressView.swift`, `HistoryOrderProductItemView.swift`
- delete `StatusItemsView.swift`, `StatusItemView.swift`, `HistoryOrderDetailDetailView.swift`

- [ ] New `HistoryOrderDetailView` body: nav bar, `OrderProgressCard`, four cards, cancel
      button; `.onAppear` also calls `loadStatusHistory`.
- [ ] Restyle each subview as a titled card using `ProfileDesign` tokens.
- [ ] `HistoryOrderAddressView` currently titles itself `L10n.Profile.status` while
      showing an address — retitle it to pickup details.
- [ ] Delete the three orphaned files and drop their `project.pbxproj` entries.
- [ ] Verify: no reference to the deleted types survives (`grep`).

### Task 6: Register files, build, verify

**Files:** modify `TrinhsGroup.xcodeproj/project.pbxproj`

- [ ] Add the three new files (build file + file ref + group child + Sources phase).
- [ ] Remove the three deleted files' four entries each.
- [ ] Verify: `xcodebuild` Debug **and** Release both succeed; the new-file count in the
      Sources phase matches; no new warnings in app code.

### Task 7: Manual + curl verification

- [ ] `curl` the new route with a real JWT: own order 200 with ≥2 history entries,
      another account's order 403, nonexistent 404, no token 401.
- [ ] On device: an order in each of the seven statuses; reduce-motion on; and the
      pre-deploy case (endpoint 404) still renders a two-point timeline.

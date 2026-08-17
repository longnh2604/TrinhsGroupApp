# Order Status Screen Redesign — Design

**Date:** 2026-07-28
**Scope:** the whole order detail screen (`HistoryOrderDetailView`), with the status
timeline as its centrepiece.

## Goal

Turn the order detail screen into something a restaurant customer reads at a glance:
which stage their food is at, in plain language, with an icon and motion that match the
stage. Replace raw WooCommerce slugs (`ON-HOLD`, `PROCESSING`) with human copy, and give
every stage a real timestamp instead of only the current one.

## Why the current screen falls short

`StatusItemsView` → `StatusItemView` draws a timeline out of grey `Rectangle`s and
`Circle`s. Every node's label is the raw status slug uppercased, padded 4pt, inside a
4pt-radius box. There is no icon, no animation, and no explanation of what a status
*means*. Only the current node shows a date, and that date is `order.dateModified` for
whichever node happens to be current — so the timeline carries one timestamp total.

## Constraints discovered before designing

These are facts verified against the installed code, not assumptions.

1. **Deployment target is 16.6** (`project.pbxproj`). `.symbolEffect`, `PhaseAnimator`
   and `ContentTransition.symbolEffect` are iOS 17 — unavailable. All motion is
   hand-rolled with `withAnimation` / `repeatForever`.
2. **Lottie is already a dependency** (`pod 'lottie-ios'`, wrapper `LottieView` in
   `Helpers/LottieLoadingView.swift`) and **`Resources/cookLoading.json` already ships**.

   **Correction made during implementation:** that file is not a cooking icon. It is
   200×200 with eight layers, five of them *text* layers spelling `Cooking`, `.`, `. 2`,
   `. 3`, `. 4` — it renders the words "Cooking...." with bouncing dots, sized for the
   200pt loading overlay it was built for. Inside the hero's 74pt circle the words are
   unreadable, and the hero already says "In the Kitchen".

   `cookLoading.json` is therefore left alone, still serving `LottieLoadingView`.

## Hero animations

Five purpose-made Lottie files were supplied and are bundled in `Resources/`:

| status | file | canvas | duration | size |
|---|---|---|---|---|
| `on-hold` | `Order_onHold.json` | 86×86 | 3.0s | 10 KB |
| `processing` | `Order_processing.json` | 375×216 | 30.6s | 421 KB |
| `completed` | `Order_ready.json` | 585×634 | 5.0s | 66 KB |
| `refunded` | `Order_refunded.json` | 1080×1080 | 2.0s | 6 KB |
| `failed` | `Order_failed.json` | 72×72 | 5.4s | 7 KB |

509 KB added to the bundle, 421 KB of it `Order_processing`.

None contains a text layer. Layer names confirm the artwork matches the status —
`Order_processing` has `pancook`, `oliveoil`, `pepper`, `bubble`, `cuiller`;
`Order_failed`'s layers are literally named `mouth/Payment failed Outlines`.

`pending` and `cancelled` have no file supplied and keep the SF Symbol treatment. Reusing
`Order_failed` for `cancelled` was rejected: a customer cancelling their own order is not a
payment failure.

Two consequences for the hero:

1. **No tinted circle behind a Lottie.** `Order_processing` carries a `White Solid 4`
   layer — `#ffffff`, opacity 100, not hidden, not a matte, 750×1334 — so it paints an
   opaque white rectangle over its whole frame. A tinted circle behind it would simply be
   covered. Statuses that fall back to an SF Symbol keep the circle.
2. **A 168×104 box, not a square.** `Order_processing` is 1.74:1; a square frame would
   letterbox that kitchen scene to about half the height of the other animations. Measured
   results: 168×96 for processing, 104×104 for the three square files, 95×103 for
   `Order_ready`.

The pulse ring is suppressed for terminal statuses — a pulse says "we are working on it" —
but the Lottie itself plays, because `Order_refunded` and `Order_failed` were authored for
exactly those states. Only Reduce Motion stops them.

One caveat worth checking on device: `Order_refunded`'s two layers are named
`Layer 1/Processing Outlines` and `Layer 2/Processing Outlines`, suggesting it was derived
from a generic processing spinner rather than drawn for refunds.
3. **WooCommerce 10.8.1 records every status transition as an order note.**
   `class-wc-order.php:464` writes `"Order status changed from %1$s to %2$s."` via
   `add_status_transition_note`, tagged `note_group = order_update`. Readable through
   `wc_get_order_notes()`. So per-stage timestamps are recoverable from data that
   already exists — no new write path, and historical orders are covered too.
4. **But WooCommerce skips the note for the first transition out of a draft.**
   `class-wc-order.php:462` excludes `draft`, `auto-draft`, `new`, `checkout-draft` as
   the `from` status. Orders created through the website checkout therefore have **no
   note for their initial status**. The timeline must anchor its first step on
   `date_created` rather than trusting notes to cover it.
5. **`project.pbxproj` is `objectVersion = 55` with no
   `PBXFileSystemSynchronizedRootGroup`.** New Swift files must be registered manually
   (PBXBuildFile + PBXFileReference + group children + Sources phase). Verified by build.

## Pre-existing bug found in passing (out of scope, flagged not fixed)

Two call sites read `order.date_created` with contradictory timezone assumptions:

- `Utility/Extensions.swift:82` — `input.timeZone = TimeZone(secondsFromGMT: 0)`,
  i.e. treats the string as **UTC**.
- `View/Profile/MyOrdersView.swift:36` — `formatter.timeZone = Australia/Sydney`,
  i.e. treats the same string as **site-local**.

WooCommerce REST emits `date_created` in site time and `date_created_gmt` in UTC, so one
of these is wrong. If the site's timezone is Melbourne, every time rendered through
`toAustraliaDateTime()` is 10–11 hours off. Fixing it changes displayed times on *every*
screen, so it needs an explicit decision and is deliberately not part of this work.

**This design sidesteps the ambiguity** rather than inheriting it: the new endpoint
returns `at_gmt` alongside `at`, and the client formats from `at_gmt`, which
`toAustraliaDateTime()` handles correctly.

## Status vocabulary — one source of truth

`OrderStatusPresentation` maps a WooCommerce slug to everything the UI needs. Nothing
else in the app is allowed to invent status copy or colour.

| slug | reached stage | title | subtitle | icon | tint |
|---|---|---|---|---|---|
| `pending` | Placed | Awaiting Payment | Finish paying to send your order to the kitchen. | `creditcard.trianglebadge.exclamationmark` | amber |
| `on-hold` | Received | Order Received | We're confirming your order with the kitchen. | `bell.badge.fill` | brand red |
| `processing` | Cooking | In the Kitchen | Our chefs are cooking your food right now. | `flame.fill` + `cookLoading.json` | orange |
| `completed` | Ready | Ready for Pickup | Your order is ready — enjoy your meal! | `checkmark.seal.fill` | green |
| `cancelled` | terminal | Order Cancelled | This order was cancelled. | `xmark.circle.fill` | red |
| `refunded` | terminal | Order Refunded | Your payment has been returned. | `arrow.uturn.backward.circle.fill` | orange |
| `failed` | terminal | Payment Failed | The payment didn't go through. | `exclamationmark.triangle.fill` | red |

The happy-path stepper is always four fixed nodes: **Order Placed → Order Received → In
the Kitchen → Ready for Pickup**.

`pending` deliberately does **not** reach node 2. An unpaid order genuinely has not been
confirmed, and the hero says "Awaiting Payment" — the screen should show where the order
is stuck, not flatter it.

Terminal statuses replace the remaining nodes with a single terminal node appended after
the last stage actually reached; the rail past that point goes grey.

## Screen layout

```
┌──────────────────────────────────────┐
│  ✕              Order #1234          │  nav bar
├──────────────────────────────────────┤
│            ╭──────────╮              │
│            │ 🍳 Lottie│  ← halo pulse│  HERO
│            ╰──────────╯              │
│           In the Kitchen             │
│  Our chefs are cooking your food     │
│                                      │
│  ORDER PROGRESS                      │
│  ●  Order Placed        6:12 PM      │  rail fills on appear
│  │                                   │
│  ●  Order Received      6:14 PM      │
│  │                                   │
│  ◉  In the Kitchen      6:35 PM      │  current node pulses
│  ┊                                   │  dashed rail = not reached
│  ○  Ready for Pickup                 │
├──────────────────────────────────────┤
│  ITEMS · PAYMENT · NOTE · PICKUP     │  four cards
├──────────────────────────────────────┤
│           Cancel Order               │
└──────────────────────────────────────┘
```

Hero and stepper live in one card (`OrderProgressCard`) because they describe the same
thing at two levels of detail.

The existing subviews (`HistoryOrderItemsView`, `HistoryOrderDetailPaymentView`,
`HistoryOrderNoteView`, `HistoryOrderAddressView`, `HistoryOrderProductItemView`) are
restyled **in place** as cards. File boundaries stay put so the diff stays reviewable.

`HistoryOrderDetailDetailView` is deleted: it showed order number, created date and
email, all of which the hero now carries.

## Visual language

Keeps the brand: `f9f9f9` screen background, white cards with soft shadow, OpenSans, and
`ColorPrimary`'s actual light value — coral `#FE7058`, not the deep red the palette name
suggests — as the accent. Adds a warm per-stage ramp so the screen's temperature tracks the
food's.

**Rail colouring, corrected after looking at a render.** The first implementation coloured
every node with the order's *current* status tint. On a cancelled order that painted "Order
Placed" and "Order Received" in failure red, as though the stages that had genuinely
succeeded had failed too.

Each stage now owns its colour — coral for placed and received, orange for cooking, green
for ready — while the node the order is *sitting on* takes the hero's colour so the two
agree, and only the appended terminal node is red or amber. `OrderStep.tint` is resolved in
`OrderProgressBuilder`, so the view never has to pick between competing tints.

## Motion (all iOS 16-safe)

| element | animation |
|---|---|
| hero halo | two concentric circles, `scaleEffect` + `opacity`, `.easeInOut(1.6).repeatForever(autoreverses: true)` |
| `processing` hero | `LottieView(filename: "cookLoading")`, 84×84 |
| `completed` hero | pop-in, `.spring(response: 0.45, dampingFraction: 0.6)` |
| rail | `@State` progress 0 → target, `.easeOut(0.8)` on appear |
| current stepper node | same halo pulse, smaller |
| terminal states | **static** — motion on a cancelled or failed order reads as wrong |

`@Environment(\.accessibilityReduceMotion)` short-circuits every repeating animation and
renders the final state directly.

## Server: `GET /wp-json/trinh-app/v1/me/orders/{id}/history`

Auth and ownership identical to the existing `/me/orders/{id}/cancel`: JWT required,
404 if the order does not exist, 403 if it belongs to someone else.

```json
{
  "order_id": 1234,
  "status": "processing",
  "history": [
    { "status": "placed",     "at": "2026-07-28T18:12:04", "at_gmt": "2026-07-28T08:12:04" },
    { "status": "on-hold",    "at": "2026-07-28T18:14:22", "at_gmt": "2026-07-28T08:14:22" },
    { "status": "processing", "at": "2026-07-28T18:35:10", "at_gmt": "2026-07-28T08:35:10" }
  ]
}
```

Construction, in order:

1. `placed` at `date_created` — the anchor. Necessary because of constraint 4 above, and
   `placed` is a synthetic status rather than a guess at what the initial WooCommerce
   status was (a bank-transfer order starts `on-hold`, not `pending`).
2. Every transition note that parses, at its `date_created`.
3. The current status at `date_modified`, **only if** no entry already carries it.
4. Sort ascending, then collapse consecutive duplicates keeping the earliest.

Status display names are mapped back to slugs from `wc_get_order_statuses()` at runtime,
so the parse does not hardcode English and survives a locale change.

Step 3 is what makes the endpoint degrade instead of break: if the note wording ever
changes and every parse fails, the response still carries placement and current status —
exactly the information the screen has today.

Plugin version goes to 1.1.0.

## Client degradation

The progress card renders from the fetched history when it has one, and otherwise derives
the timeline from `order.status` + `dateCreated` + `dateModified` — today's behaviour.

This matters concretely: the WordPress side deploys by hand, so a build will reach devices
before the endpoint exists. A 404 must look like a slightly less detailed timeline, never
like a broken screen.

## Testing

- Standalone Swift tests for the pure logic: slug → presentation mapping, stage ordering,
  terminal handling, `pending` not reaching node 2, history → node-state reduction,
  fallback timeline when history is empty.
- `xcodebuild` Debug **and** Release, since new files are being hand-registered in
  `project.pbxproj`.
- `curl` against the new endpoint with a real JWT: own order 200, someone else's 403,
  nonexistent 404.
- Manual: an order in each of the seven statuses, plus reduce-motion on.

## Deliberately not included

- **The status badge in `OrderHistoryItemView`** (order list) still prints
  `PROCESSING`, with its own private `getStatusColor`. After this change the list and the
  detail screen describe the same order in different vocabularies. Reusing
  `OrderStatusPresentation` there is roughly three lines; it is left out because the chosen
  scope was the detail screen, and it is recorded here as the obvious follow-up.
- **The timezone bug** above.

## Cleanup this change pulled in

- `HistoryOrderDetailPaymentView`, `HistoryOrderProductItemView` and
  `HistoryOrderDetailDetailView` each declared `@EnvironmentObject var mainViewModel:
  MainViewModel` and never read it. `NewNotificationsView` injects only `historyViewModel`
  and `authViewModel` into the cover it presents this screen from, so the declarations were
  a dependency the notification path does not supply — a latent crash. Removed; unverified
  whether it ever fired, since environment propagation through `fullScreenCover` is
  version-dependent.
- `HistoryOrderAddressView` was titled with the generic "Status" string while showing an
  address. Retitled to "Pickup Details".
- `profile.orderStatus` and `profile.status` were left with no callers by the deletions and
  the retitle, and were removed from `L10n.swift` and `Localizable.strings`.

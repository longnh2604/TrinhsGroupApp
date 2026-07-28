# Tapping a notification opens that order's status detail

Date: 2026-07-28
Status: approved, ready for implementation planning

## Problem

In the in-app notification list (`NewNotificationsView`, reached from the bell on `HomeView`),
tapping an item does nothing useful. Items in the "New" section only get marked read; items in
the "Earlier" section have no tap handler at all. A customer who sees "Order Ready! 🎉" has no
way to get from that notification to the order.

Two things block this today:

1. **`AppNotification` does not carry an order id.** Its `id` is the APNs request identifier,
   not the order. `AppDelegate.didReceive` (AppDelegate.swift:126) *does* read `order_id` out
   of the push payload, but only forwards it via `NotificationCenter` and `UserDefaults` — it
   is never stored on the notification. So the bell has nothing to navigate with.
2. **`HistoryOrderDetailView` is only presented inside `MyOrdersView`** (MyOrdersView.swift:151),
   gated on `historyViewModel.showHistoryOrderDetail`. The notification list is a
   `fullScreenCover` over `HomeView` (tab 0), while `MyOrdersView` is tab 2. Worse,
   `MainView.swift:51` sets `showHistoryOrderDetail = false` on every tab change, which would
   actively cancel any attempt to drive that flag from the notification list.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Where the user lands | Detail opens **over the notification list** | Closing the detail returns to the list so the customer can read the next one. No tab switching, and no need to touch `MainView`'s reset logic. |
| Order data freshness | **Always re-fetch before opening** | A notification means the status changed server-side. `HistoryViewModel` already documents this for the banner-tap path: *"Notification tap means a status changed on the server — never trust the local cache."* Showing a cached "Processing" under a "Ready" notification would contradict itself. Cost is a spinner on each tap. |
| Pre-existing bell entries | **Not tappable** | They were persisted before `orderID` existed, so they have none. Deriving it by parsing `"Order #1234"` out of the body would break the moment the wording changes. They age out on their own. |

## Design

### Data — carry the order id into the store

`AppNotification` gains `orderID: Int?`. It is captured at all three points where a
notification enters `NotificationStore`:

| Ingestion point | Source of the id |
|---|---|
| `AppDelegate.userNotificationCenter(_:willPresent:)` | `notification.request.content.userInfo["order_id"]` |
| `AppDelegate.userNotificationCenter(_:didReceive:)` | already parsed there; pass it to `add` |
| `NotificationStore.syncDeliveredNotifications()` | `item.request.content.userInfo["order_id"]` |

The plugin sends `order_id` as a **string** (`trinh-push-notify.php`: `'order_id' => (string) $order_id`),
so parsing must accept a string and tolerate an absent or non-numeric value.

`NotificationStore.add` takes a new `orderID: Int?` parameter, defaulting to `nil`.

**Backward compatibility is the highest-risk part of this change:** the store is persisted in
UserDefaults on real devices. `AppNotification` already has a custom `init(from:)` for legacy
entries; it must decode `orderID` with `decodeIfPresent` so existing entries load as `nil`
rather than failing. A decode failure would silently empty a customer's notification history.

### Navigation state — kept separate from the Orders tab flow

`HistoryViewModel` gains:

```swift
@Published var notificationOrder: Order?              // non-nil ⇒ present the detail
@Published var isResolvingNotificationOrder = false   // drives the spinner
private var pendingNotificationOrderID: Int?
func openOrderFromNotification(orderID: Int)
```

`openOrderFromNotification` records `pendingNotificationOrderID`, sets
`isResolvingNotificationOrder = true`, and calls `service.onFetchHistoryOrders()`.

Resolution happens in the **existing** `historyOrdersPublisher` sink, using
`pendingNotificationOrderID` — deliberately a separate property from the
`pendingNavigationOrderID` that the banner-tap path uses, so the two flows cannot consume each
other's pending request.

`showHistoryOrderDetail` is deliberately **not** reused: `MainView.swift:51` clears it on tab
change, and it is wired to `MyOrdersView`'s overlay.

### Presentation

`NewNotificationsView`:

- add `@EnvironmentObject var historyViewModel: HistoryViewModel` (inherited through the
  `fullScreenCover` from `HomeView`, which sits inside `MainView`'s environment)
- tap on an item **with** an `orderID` → `store.markRead(notification)` then
  `historyViewModel.openOrderFromNotification(orderID:)`
- tap on an item **without** one → mark read only, nothing opens
- **both sections get the handler.** Today only the "New" `ForEach` has `.onTapGesture`
  (NewNotificationsView.swift:99); the "Earlier" `ForEach` (line 110) has none, so read
  notifications are currently inert. Since an order stays interesting after its notification
  has been read, the same handler must be applied to both. Extract it into one shared row
  builder rather than duplicating the closure.
- `.fullScreenCover(item: $historyViewModel.notificationOrder) { HistoryOrderDetailView(order: $0, onClose: …) }`
- a loading overlay while `isResolvingNotificationOrder` is true

`HistoryOrderDetailView` gains `var onClose: (() -> Void)? = nil`. Its close button
(HistoryOrderDetailView.swift:19-21) calls `onClose?()` when provided, otherwise keeps the
current `historyViewModel.showHistoryOrderDetail = false`. This leaves `MyOrdersView`
unchanged; only the notification list passes a closure, which clears `notificationOrder`.

`Order` is already `Identifiable` (OrderModel.swift:10), so `fullScreenCover(item:)` works
without a wrapper.

### Failure handling

If the re-fetched order list does not contain the id — order deleted, or belonging to another
account — clear `isResolvingNotificationOrder`, leave `notificationOrder` nil, and set
`message` so the user sees why nothing opened. Tapping must never appear to do nothing.

A network failure during the fetch surfaces through the existing `errorPublisher`; the spinner
must still be cleared so the list is not stuck behind an overlay.

## Files touched

| File | Change |
|---|---|
| `TrinhsGroup/View/Model/NotificationModel.swift` | `orderID` on `AppNotification`; `add(orderID:)`; capture in `syncDeliveredNotifications` |
| `TrinhsGroup/App/AppDelegate.swift` | pass `order_id` into `add` from both `willPresent` and `didReceive` |
| `TrinhsGroup/View/ViewModel/HistoryViewModel.swift` | new published state, `openOrderFromNotification`, resolution in the existing sink |
| `TrinhsGroup/View/Home/NewNotificationsView.swift` | tap handling, cover presentation, spinner |
| `TrinhsGroup/View/Profile/HistoryOrderDetailView.swift` | optional `onClose` |
| `scripts/run-logic-checks.sh` | new decode suite |

## Out of scope

- Making pre-existing bell entries tappable.
- Any change to `MyOrdersView` or `MainView` navigation.
- Changing what the OS banner tap does — that path stays as it is.
- Deep links from outside the app.

## Verification

**Automated** — a new suite in `scripts/run-logic-checks.sh` compiling the real
`NotificationModel.swift`:

- legacy JSON with no `orderID` decodes, yielding `orderID == nil`
- legacy JSON with an `Int` `id` still decodes (the existing compatibility path)
- new JSON with `orderID` round-trips through encode/decode
- an entry whose `order_id` was a non-numeric string decodes with `orderID == nil` rather than
  throwing

**Manual**

1. Change an order's status in wp-admin → open the bell → tap the new item → spinner → detail
   shows the *current* status → close → back on the notification list.
2. Tap an entry that predates this change → marked read, nothing opens, no crash.
3. Tap an order that has since been deleted → spinner clears, message shown.
4. Tap with the network off → spinner clears, error surfaced, list still usable.

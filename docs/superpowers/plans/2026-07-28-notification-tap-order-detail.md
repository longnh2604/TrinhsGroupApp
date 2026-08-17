# Notification Tap → Order Detail Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tapping a notification in the in-app bell list opens that order's status detail on top of the list, showing freshly-fetched status.

**Architecture:** `AppNotification` gains an optional `orderID`, captured from the push payload at all three points where a notification enters `NotificationStore`. `HistoryViewModel` gains a navigation channel (`notificationOrder`) that is deliberately separate from the `showHistoryOrderDetail` flag used by the Orders tab, because `MainView` clears that flag on every tab change. `NewNotificationsView` presents `HistoryOrderDetailView` in a `fullScreenCover` driven by that new channel.

**Tech Stack:** Swift 5, SwiftUI, Combine, CocoaPods. Design spec: `docs/superpowers/specs/2026-07-28-notification-tap-order-detail-design.md`

## Global Constraints

- **There is no XCTest target in this project.** Do not write XCTest files and do not try to add a test target. Automated tests go into `scripts/run-logic-checks.sh`, which compiles real source with `swiftc` and asserts on it. UI behaviour is verified by building and by the manual script in Task 6.
- `NotificationModel.swift` **cannot be compiled standalone** — `NotificationStore` calls `UserDefaultsManager`, which pulls in `Product` → `AnyCodableValue` → SwiftUI. Test suites must **extract the `AppNotification` struct by line range**, the same technique `scripts/run-logic-checks.sh` already uses for `getDiscountPercentage`.
- iOS deployment target is **16.6**. `.fullScreenCover(item:)`, `.banner` presentation options and `@Published` bindings on `EnvironmentObject` are all available.
- **Do not modify `MainView.swift`** and **do not change `showHistoryOrderDetail` semantics.** `MainView.swift:51` clears that flag on tab change; the new flow must not depend on it.
- **`MyOrdersView` must keep working unchanged.** It presents the same `HistoryOrderDetailView` (MyOrdersView.swift:151-152).
- The WordPress plugin sends `order_id` as a **string**: `'order_id' => (string) $order_id`. Parsing must accept a string, and tolerate absent or non-numeric values.
- Build command used throughout:
  ```bash
  xcodebuild build -workspace TrinhsGroup.xcworkspace -scheme TrinhsGroup \
    -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -configuration Debug \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | grep -E "error:|^\*\* BUILD"
  ```
- The repository has a large uncommitted changeset from unrelated work. Every commit step below stages **only the named files** — never use `git add -A` or `git add .`.

---

### Task 1: `AppNotification.orderID` with backward-compatible decoding

The highest-risk change in this feature. `NotificationStore` persists to UserDefaults on real devices, so a decode regression silently wipes a customer's notification history.

**Files:**
- Modify: `TrinhsGroup/View/Model/NotificationModel.swift:11-41` (the `AppNotification` struct)
- Modify: `scripts/run-logic-checks.sh` (add a suite)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `AppNotification.orderID: Int?` — stored property, defaults to `nil`
  - `AppNotification.init(id:title:content:date:isRead:orderID:)` — memberwise-style init with `orderID: Int? = nil` last, so existing call sites keep compiling
  - `static func AppNotification.orderID(from userInfo: [AnyHashable: Any]) -> Int?` — parses the push payload's `order_id`

- [ ] **Step 1: Write the failing test suite**

Add this function to `scripts/run-logic-checks.sh`, immediately **before** the `suite_discount` definition:

```bash
# ── Suite: AppNotification decoding ─────────────────────────────────────────────
# The bell history is persisted in UserDefaults on real devices, so this struct must
# keep decoding entries written by older builds. A throw here would silently empty a
# customer's notification list.
suite_notification_decode() {
    local d="$WORK/notification"; mkdir -p "$d"
    python3 - "$SRC/View/Model/NotificationModel.swift" "$d/subject.swift" <<'PY' || exit 2
import sys
src = open(sys.argv[1]).read().split('\n')
try:
    s = next(i for i, l in enumerate(src) if l.startswith('struct AppNotification'))
except StopIteration:
    sys.exit("struct AppNotification not found — did it move or get renamed?")
# closing brace of the struct is the first line that is exactly '}'
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
```

Then register it by changing the two invocation lines near the bottom of the file from:

```bash
suite_discount
suite_points_decode
```

to:

```bash
suite_notification_decode
suite_discount
suite_points_decode
```

- [ ] **Step 2: Run the suite to verify it fails**

Run: `./scripts/run-logic-checks.sh`

Expected: the `AppNotification decoding` suite fails to compile, with errors like
`value of type 'AppNotification' has no member 'orderID'` and
`type 'AppNotification' has no member 'orderID(from:)'`. The other two suites still pass.

- [ ] **Step 3: Implement the model change**

Replace `TrinhsGroup/View/Model/NotificationModel.swift` lines 11-41 (the whole `AppNotification` struct) with:

```swift
struct AppNotification: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var content: String
    var date: Date = Date()
    var isRead: Bool = false
    /// WooCommerce order this notification is about, when the push carried one.
    /// `nil` for entries stored before this field existed — those are not tappable.
    var orderID: Int?

    init(id: String = UUID().uuidString,
         title: String,
         content: String,
         date: Date = Date(),
         isRead: Bool = false,
         orderID: Int? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.isRead = isRead
        self.orderID = orderID
    }

    // Backward-compatible decoding: legacy entries had an Int id and no date/isRead/orderID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringID = try? container.decode(String.self, forKey: .id) {
            id = stringID
        } else if let intID = try? container.decode(Int.self, forKey: .id) {
            id = String(intID)
        } else {
            id = UUID().uuidString
        }
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        isRead = (try? container.decode(Bool.self, forKey: .isRead)) ?? true
        orderID = try? container.decodeIfPresent(Int.self, forKey: .orderID)
    }

    /// Pull the order id out of a push payload.
    ///
    /// `trinh-push-notify` sends it as a string (`'order_id' => (string) $order_id`), but
    /// accept a number too so a future payload change cannot silently break navigation.
    static func orderID(from userInfo: [AnyHashable: Any]) -> Int? {
        if let value = userInfo["order_id"] as? Int { return value }
        if let text = userInfo["order_id"] as? String { return Int(text) }
        return nil
    }
}
```

- [ ] **Step 4: Run the suite to verify it passes**

Run: `./scripts/run-logic-checks.sh`

Expected: `all 3 suite(s) passed`, exit code 0.

- [ ] **Step 5: Build**

Run the build command from Global Constraints.
Expected: `** BUILD SUCCEEDED **`. No call site breaks, because `orderID` is the last parameter and defaults to `nil`.

- [ ] **Step 6: Commit**

```bash
git add TrinhsGroup/View/Model/NotificationModel.swift scripts/run-logic-checks.sh
git commit -m "feat(notifications): carry order id on AppNotification"
```

---

### Task 2: Capture `order_id` at all three ingestion points

**Files:**
- Modify: `TrinhsGroup/View/Model/NotificationModel.swift` (`NotificationStore.add`, `syncDeliveredNotifications`)
- Modify: `TrinhsGroup/App/AppDelegate.swift` (`willPresent` ~line 103, `didReceive` ~line 119)

**Interfaces:**
- Consumes: `AppNotification.orderID(from:)` and `AppNotification.init(…orderID:)` from Task 1.
- Produces: `NotificationStore.add(id:title:content:date:isRead:orderID:)` — `orderID: Int? = nil` added last. Stored notifications now carry an order id whenever the push had one.

- [ ] **Step 1: Add `orderID` to `NotificationStore.add`**

In `TrinhsGroup/View/Model/NotificationModel.swift`, replace the `add` method (currently lines 68-83) with:

```swift
    /// Add a notification if it isn't already stored. Safe to call from any thread.
    func add(id: String,
             title: String,
             content: String,
             date: Date = Date(),
             isRead: Bool = false,
             orderID: Int? = nil) {
        guard !title.isEmpty || !content.isEmpty else { return }
        DispatchQueue.main.async {
            if let index = self.notifications.firstIndex(where: { $0.id == id }) {
                if isRead && !self.notifications[index].isRead {
                    self.notifications[index].isRead = true
                    self.persist()
                }
                // An entry stored before this build had no order id. Backfill it so a
                // notification that arrives again, or is re-synced from Notification
                // Center, becomes tappable.
                if self.notifications[index].orderID == nil, let orderID {
                    self.notifications[index].orderID = orderID
                    self.persist()
                }
                return
            }
            self.notifications.insert(
                AppNotification(id: id, title: title, content: content,
                                date: date, isRead: isRead, orderID: orderID),
                at: 0
            )
            self.notifications.sort(by: { $0.date > $1.date })
            self.persist()
        }
    }
```

- [ ] **Step 2: Capture the id in `syncDeliveredNotifications`**

In the same file, replace `syncDeliveredNotifications` (currently lines 107-117) with:

```swift
    /// Pick up pushes that arrived while the app was closed and are still in
    /// the system Notification Center.
    func syncDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
            for item in delivered {
                let content = item.request.content
                self.add(id: item.request.identifier,
                         title: content.title,
                         content: content.body,
                         date: item.date,
                         orderID: AppNotification.orderID(from: content.userInfo))
            }
        }
    }
```

- [ ] **Step 3: Capture the id in `willPresent`**

In `TrinhsGroup/App/AppDelegate.swift`, inside `userNotificationCenter(_:willPresent:withCompletionHandler:)`, replace the `NotificationStore.shared.add(...)` call with:

```swift
        NotificationStore.shared.add(id: notification.request.identifier,
                                     title: content.title,
                                     content: content.body,
                                     date: notification.date,
                                     orderID: AppNotification.orderID(from: content.userInfo))
```

- [ ] **Step 4: Capture the id in `didReceive`**

In the same file, inside `userNotificationCenter(_:didReceive:withCompletionHandler:)`, the method already parses `order_id` further down. Restructure so it is parsed once, before the `add` call. Replace the body from `let tappedContent = …` through the closing brace of the `if let orderIDString …` block with:

```swift
        let tappedContent = response.notification.request.content
        let userInfo = tappedContent.userInfo
        let orderID = AppNotification.orderID(from: userInfo)

        NotificationStore.shared.add(id: response.notification.request.identifier,
                                     title: tappedContent.title,
                                     content: tappedContent.body,
                                     date: response.notification.date,
                                     isRead: true,
                                     orderID: orderID)

        if let orderID {
            // Store for cold-launch support; HistoryViewModel also reads this on orders load
            UserDefaults.standard.set(orderID, forKey: "pending_order_id")
            NotificationCenter.default.post(
                name: .didTapOrderNotification,
                object: nil,
                userInfo: ["order_id": orderID]
            )
        }
```

- [ ] **Step 5: Build and re-run the logic checks**

Run the build command from Global Constraints, then `./scripts/run-logic-checks.sh`.
Expected: `** BUILD SUCCEEDED **` and `all 3 suite(s) passed`.

- [ ] **Step 6: Commit**

```bash
git add TrinhsGroup/View/Model/NotificationModel.swift TrinhsGroup/App/AppDelegate.swift
git commit -m "feat(notifications): store order id from every push ingestion point"
```

---

### Task 3: `HistoryViewModel` navigation channel

**Files:**
- Modify: `TrinhsGroup/View/ViewModel/HistoryViewModel.swift` (properties ~13-27, `historyOrdersPublisher` sink ~52-64, new method)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `HistoryViewModel.notificationOrder: Order?` — `@Published`; non-nil means "present the detail from the notification list"
  - `HistoryViewModel.isResolvingNotificationOrder: Bool` — `@Published`; drives the spinner
  - `HistoryViewModel.openOrderFromNotification(orderID: Int)` — re-fetches, then sets `notificationOrder`

- [ ] **Step 1: Add the published state**

In `TrinhsGroup/View/ViewModel/HistoryViewModel.swift`, after `@Published var message: String = ""` (line 20), add:

```swift
    /// Non-nil while the order detail opened from the in-app notification list is showing.
    ///
    /// Deliberately separate from `showHistoryOrderDetail`: that flag drives MyOrdersView's
    /// overlay and MainView.swift:51 clears it on every tab change, which would cancel a
    /// presentation started from the notification list.
    @Published var notificationOrder: Order?
    @Published var isResolvingNotificationOrder = false
```

And after `private var pendingNavigationOrderID: Int?` (line 25), add:

```swift
    // Separate from pendingNavigationOrderID so the notification-list flow and the
    // OS-banner-tap flow cannot consume each other's pending request.
    private var pendingNotificationOrderID: Int?
```

- [ ] **Step 2: Add the resolution to the existing orders sink**

In `bindingData()`, in the `service.historyOrdersPublisher` sink, add `self.resolvePendingNotificationOrder(in: orders)` immediately after the existing `self.resolvePendingNavigation()` line, so the sink body ends:

```swift
                self.resolvePendingNavigation()
                self.resolvePendingNotificationOrder(in: orders)
```

- [ ] **Step 3: Add the public entry point and its resolver**

Add these two methods at the end of the class, after `resolvePendingNavigation()`:

```swift
    // MARK: - Order detail opened from the in-app notification list

    /// Open the order detail for a notification the user tapped inside the app.
    ///
    /// Always re-fetches rather than trusting `orders`: a notification means the status
    /// changed on the server, so a cached order could contradict the message the user just
    /// tapped.
    func openOrderFromNotification(orderID: Int) {
        pendingNotificationOrderID = orderID
        isResolvingNotificationOrder = true
        message = ""
        service.onFetchHistoryOrders()
    }

    func dismissNotificationOrder() {
        notificationOrder = nil
    }

    private func resolvePendingNotificationOrder(in orders: [Order]) {
        guard let orderID = pendingNotificationOrderID else { return }
        pendingNotificationOrderID = nil
        isResolvingNotificationOrder = false

        if let order = orders.first(where: { $0.id == orderID }) {
            notificationOrder = order
        } else {
            // Never let a tap appear to do nothing.
            message = "That order is no longer available."
        }
    }
```

- [ ] **Step 4: Make sure a failed fetch clears the spinner**

The orders sink only fires on success, so a network failure would leave the spinner up forever. In `bindingData()`, in the existing `service.errorPublisher` sink, add the two reset lines so its body reads:

```swift
            .sink { [weak self] error in
                self?.message = error
                // A failed fetch never reaches historyOrdersPublisher, so release the
                // notification-list spinner here or it stays up forever.
                self?.pendingNotificationOrderID = nil
                self?.isResolvingNotificationOrder = false
            }
```

- [ ] **Step 5: Build**

Run the build command from Global Constraints.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add TrinhsGroup/View/ViewModel/HistoryViewModel.swift
git commit -m "feat(orders): add notification-list navigation channel to HistoryViewModel"
```

---

### Task 4: Make `HistoryOrderDetailView` dismissal configurable

Small, but it touches a view `MyOrdersView` already presents, so it gets its own verification gate.

**Files:**
- Modify: `TrinhsGroup/View/Profile/HistoryOrderDetailView.swift:10-28`

**Interfaces:**
- Consumes: nothing.
- Produces: `HistoryOrderDetailView(order:onClose:)` — `onClose: (() -> Void)? = nil`. When nil, the close button keeps its current behaviour of setting `historyViewModel.showHistoryOrderDetail = false`, so `MyOrdersView` needs no change.

- [ ] **Step 1: Add the optional closure**

In `TrinhsGroup/View/Profile/HistoryOrderDetailView.swift`, change the stored properties (line 14) from:

```swift
    var order: Order
```

to:

```swift
    var order: Order
    /// How to dismiss. `nil` keeps the original behaviour — clearing
    /// `showHistoryOrderDetail`, which is what MyOrdersView's overlay is driven by.
    /// The in-app notification list passes its own closure instead, because it presents
    /// this view from a different piece of state.
    var onClose: (() -> Void)? = nil
```

- [ ] **Step 2: Route the close button through it**

Change the close button action (lines 19-21) from:

```swift
            Button(action: {
                historyViewModel.showHistoryOrderDetail = false
            }) {
```

to:

```swift
            Button(action: {
                if let onClose {
                    onClose()
                } else {
                    historyViewModel.showHistoryOrderDetail = false
                }
            }) {
```

- [ ] **Step 3: Build**

Run the build command from Global Constraints.
Expected: `** BUILD SUCCEEDED **`. `MyOrdersView.swift:152` calls `HistoryOrderDetailView(order:)` and still compiles because `onClose` defaults to `nil`.

- [ ] **Step 4: Verify the existing screen still closes**

Run the app in a simulator, log in, go to the Orders tab, open an order, tap the ✕.
Expected: the detail closes exactly as before. This is a regression check on `MyOrdersView`, not on the new feature.

- [ ] **Step 5: Commit**

```bash
git add TrinhsGroup/View/Profile/HistoryOrderDetailView.swift
git commit -m "refactor(orders): allow HistoryOrderDetailView to take a custom dismiss"
```

---

### Task 5: Tap handling and presentation in `NewNotificationsView`

**Files:**
- Modify: `TrinhsGroup/View/Home/NewNotificationsView.swift:10-13` (properties), `:92-124` (body)

**Interfaces:**
- Consumes: `AppNotification.orderID` (Task 1), `HistoryViewModel.notificationOrder` / `isResolvingNotificationOrder` / `openOrderFromNotification(orderID:)` / `dismissNotificationOrder()` (Task 3), `HistoryOrderDetailView(order:onClose:)` (Task 4).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the environment object**

In `TrinhsGroup/View/Home/NewNotificationsView.swift`, after `@ObservedObject var store = NotificationStore.shared` (line 12), add:

```swift
    // Provided by MainView; inherited through HomeView's fullScreenCover.
    @EnvironmentObject var historyViewModel: HistoryViewModel
```

- [ ] **Step 2: Add one shared row builder**

Add this method to the `NewNotificationsView` struct, just above `var body: some View`:

```swift
    /// One row, used by both sections. Previously only the "New" section had a tap
    /// gesture, which left every already-read notification inert.
    @ViewBuilder
    private func row(_ notification: AppNotification) -> some View {
        NotificationItemView(notification: notification)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    store.markRead(notification)
                }
                // Entries stored before orderID existed simply mark read.
                if let orderID = notification.orderID {
                    historyViewModel.openOrderFromNotification(orderID: orderID)
                }
            }
    }
```

`.contentShape(Rectangle())` makes the whole row tappable, not just its painted pixels.

- [ ] **Step 3: Use the row builder in both sections**

Replace the two `ForEach` blocks (lines 96-104 and 110-113) so the `VStack` reads:

```swift
                        VStack(spacing: 10) {
                            if !unread.isEmpty {
                                sectionHeader("New")
                                ForEach(unread) { notification in
                                    row(notification)
                                }
                            }

                            if !earlier.isEmpty {
                                sectionHeader("Earlier")
                                    .padding(.top, unread.isEmpty ? 0 : 8)
                                ForEach(earlier) { notification in
                                    row(notification)
                                }
                            }
                        }
                        .padding(.vertical, 12)
```

- [ ] **Step 4: Present the detail and the spinner**

Replace the `.onAppear` modifier at the end of `body` (lines 121-123) with:

```swift
        .overlay {
            if historyViewModel.isResolvingNotificationOrder {
                LoadingView()
                    .ignoresSafeArea()
            }
        }
        .onAppear(perform: {
            store.syncDeliveredNotifications()
        })
        .fullScreenCover(item: $historyViewModel.notificationOrder) { order in
            HistoryOrderDetailView(order: order) {
                historyViewModel.dismissNotificationOrder()
            }
            .environmentObject(historyViewModel)
        }
```

`Order` already conforms to `Identifiable` (`OrderModel.swift:10`), so `fullScreenCover(item:)` needs no wrapper. `HistoryOrderDetailView` also reads `authViewModel` from the environment; a `fullScreenCover` inherits it from the presenting hierarchy, so no extra injection is needed — Step 6 confirms this at runtime.

- [ ] **Step 5: Build**

Run the build command from Global Constraints.
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Verify the environment reaches the cover**

Run the app, log in, open the bell, tap a notification that has an order id.
Expected: spinner, then the order detail. If the app crashes with
`No ObservableObject of type AuthViewModel found`, add `.environmentObject(authViewModel)` to
the `HistoryOrderDetailView` in Step 4 and declare `@EnvironmentObject var authViewModel: AuthViewModel`
on `NewNotificationsView`.

- [ ] **Step 7: Commit**

```bash
git add TrinhsGroup/View/Home/NewNotificationsView.swift
git commit -m "feat(notifications): tap a notification to open its order detail"
```

---

### Task 6: End-to-end manual verification

No code. This is the gate that the feature actually works against the live server, since none of the presentation logic is covered by automated tests.

**Files:** none.

**Interfaces:** none.

- [ ] **Step 1: Confirm the automated checks still pass**

```bash
./scripts/run-logic-checks.sh
```
Expected: `all 3 suite(s) passed`.

- [ ] **Step 2: Happy path**

Log into the app on a device with push working. In wp-admin, change one of that customer's
orders to **Processing**. When the push arrives, open the bell and tap the new item.

Expected: brief spinner → order detail showing status **Processing** (matching the
notification, not a stale cached status) → tap ✕ → back on the notification list, which is
still open.

- [ ] **Step 3: Read notifications are tappable too**

Tap the same notification again, now in the "Earlier" section.
Expected: it opens the detail again. Before this change, read notifications did nothing.

- [ ] **Step 4: Legacy entry**

Find a notification that predates this build (no `orderID`) and tap it.
Expected: it marks read, nothing opens, no crash, no spinner left on screen.

- [ ] **Step 5: Missing order**

Delete an order in wp-admin that you have a notification for, then tap that notification.
Expected: spinner clears and "That order is no longer available." surfaces. The list stays usable.

- [ ] **Step 6: Network failure**

Turn on Airplane Mode and tap a notification with an order id.
Expected: spinner clears, an error message surfaces, the list is still usable — **not** stuck
behind the overlay.

- [ ] **Step 7: No regression on the Orders tab**

Go to the Orders tab, open an order, close it. Then tap an OS notification banner from the
lock screen.
Expected: both behave exactly as before this feature.

---

## Self-Review

**Spec coverage**

| Spec requirement | Task |
|---|---|
| `AppNotification.orderID` | 1 |
| Backward-compatible decode of persisted entries | 1 (steps 1-4) |
| `order_id` sent as a string | 1 (`orderID(from:)`, tested) |
| Capture at `willPresent` | 2 (step 3) |
| Capture at `didReceive` | 2 (step 4) |
| Capture at `syncDeliveredNotifications` | 2 (step 2) |
| `notificationOrder` / `isResolvingNotificationOrder` / `openOrderFromNotification` | 3 |
| Separate pending id from the banner path | 3 (step 1) |
| Do not reuse `showHistoryOrderDetail`; do not touch `MainView` | 3 (step 1 comment), enforced by Global Constraints |
| Configurable `onClose`, `MyOrdersView` unchanged | 4 |
| Tap handler on **both** sections via one shared builder | 5 (steps 2-3) |
| Legacy entries not tappable | 5 (step 2), verified 6.4 |
| `fullScreenCover(item:)` + spinner | 5 (step 4) |
| Order-not-found handling | 3 (step 3), verified 6.5 |
| Network-failure spinner release | 3 (step 4), verified 6.6 |
| Decode test suite | 1 (step 1) |
| Manual verification script | 6 |

No spec requirement is unassigned.

**Placeholder scan:** every code step contains complete code. No TBD/TODO, no "add error handling", no "similar to Task N".

**Type consistency:** `orderID: Int?` used identically in Tasks 1, 2 and 5. `AppNotification.orderID(from:)` defined in Task 1 step 3 and called in Task 2 steps 2-4 with the same signature. `openOrderFromNotification(orderID: Int)` and `dismissNotificationOrder()` defined in Task 3 step 3 and called in Task 5 steps 2 and 4 with matching names. `HistoryOrderDetailView(order:onClose:)` defined in Task 4 and called in Task 5 step 4 using trailing-closure syntax, which matches `onClose: (() -> Void)?`.

**Known gap, accepted:** Tasks 3, 4 and 5 have no automated coverage. `HistoryServices` is a concrete class rather than a protocol, so `HistoryViewModel` cannot be driven by a fake without a refactor that this feature does not need. Task 6 covers those paths manually, including the two failure modes.

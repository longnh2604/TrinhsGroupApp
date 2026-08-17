//
//  HistoryViewModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation
import Combine

class HistoryViewModel: ObservableObject {

    @Published var orders = [Order]()
    @Published var selectedOrder: Order = Order.default
    @Published var showHistory = false
    @Published var showHistoryOrderDetail = false
    @Published var showLoading = false
    @Published var isCancelling = false
    @Published var showCancelConfirm = false
    @Published var message: String = ""

    /// Non-nil while the order detail opened from the in-app notification list is showing.
    ///
    /// Deliberately separate from `showHistoryOrderDetail`: that flag drives MyOrdersView's
    /// overlay and MainView.swift:51 clears it on every tab change, which would cancel a
    /// presentation started from the notification list.
    @Published var notificationOrder: Order?
    @Published var isResolvingNotificationOrder = false

    /// Timestamped stages for the order whose detail is on screen. Empty until the fetch
    /// lands, and stays empty if the server has no history to give — `OrderProgressCard`
    /// falls back to the order's own dates in that case.
    @Published var statusHistory: [OrderTimelineEvent] = []

    private var service: HistoryServices = HistoryServices()
    private var cancellableSet: Set<AnyCancellable> = []
    // Holds an order_id from a notification tap that arrived before orders were loaded
    private var pendingNavigationOrderID: Int?
    // Separate from pendingNavigationOrderID so the notification-list flow and the
    // OS-banner-tap flow cannot consume each other's pending request.
    private var pendingNotificationOrderID: Int?
    // Which order `statusHistory` belongs to, so a slow response for a previously viewed
    // order cannot land on the rail of the one now on screen.
    private var statusHistoryOrderID: Int?
    // Last customer ID used for fetch — needed to re-fetch on notification tap
    private var lastCustomerId: Int = 0

    init(service: HistoryServices = HistoryServices()) {
        self.service = service
        self.bindingData()
        self.observeNotificationTap()
        // Handle cold-launch tap (app was killed when notification was tapped)
        if let orderID = UserDefaults.standard.value(forKey: "pending_order_id") as? Int {
            UserDefaults.standard.removeObject(forKey: "pending_order_id")
            pendingNavigationOrderID = orderID
        }
    }

    func bindingData() {
        service.loadingPublisher
            .receive(on: RunLoop.main)
            .assign(to: &$showLoading)

        service.errorPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.message = error
                // A failed fetch never reaches historyOrdersPublisher, so release the
                // notification-list spinner here or it stays up forever.
                self?.pendingNotificationOrderID = nil
                self?.isResolvingNotificationOrder = false
            }
            .store(in: &cancellableSet)

        service.historyOrdersPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] orders in
                guard let self = self else { return }
                self.orders = orders
                // Keep selectedOrder in sync so an already-open detail view re-renders with new status
                if self.selectedOrder.id > 0,
                   let updated = orders.first(where: { $0.id == self.selectedOrder.id }) {
                    self.selectedOrder = updated
                }
                self.resolvePendingNavigation()
                self.resolvePendingNotificationOrder(in: orders)
            }
            .store(in: &cancellableSet)

        service.cancelOrderPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] updatedOrder in
                self?.isCancelling = false
                if let idx = self?.orders.firstIndex(where: { $0.id == updatedOrder.id }) {
                    self?.orders[idx] = updatedOrder
                }
                self?.selectedOrder = updatedOrder
                self?.message = "Order #\(updatedOrder.number) has been cancelled."
            }
            .store(in: &cancellableSet)

        service.cancelErrorPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.isCancelling = false
                self?.message = error
            }
            .store(in: &cancellableSet)

        service.orderHistoryPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                guard let self = self, result.orderID == self.statusHistoryOrderID else { return }
                self.statusHistory = result.history?.timelineEvents ?? []
            }
            .store(in: &cancellableSet)
    }

    func fetchOrders(customerId: Int) {
        lastCustomerId = customerId
        service.onFetchHistoryOrders()
    }

    func cancelOrder(orderID: Int) {
        isCancelling = true
        service.onCancelOrder(orderID: orderID)
    }

    /// Loads the timestamped stages for an order about to be shown.
    ///
    /// Clears the previous order's rail immediately so the new screen never shows another
    /// order's timestamps while its own request is in flight.
    func loadStatusHistory(orderID: Int) {
        if statusHistoryOrderID != orderID {
            statusHistory = []
        }
        statusHistoryOrderID = orderID
        service.onFetchOrderStatusHistory(orderID: orderID)
    }

    // MARK: - Notification tap navigation

    private func observeNotificationTap() {
        NotificationCenter.default.addObserver(
            forName: .didTapOrderNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let orderID = notification.userInfo?["order_id"] as? Int else { return }
            self?.navigateToOrder(orderID: orderID)
        }
    }

    private func navigateToOrder(orderID: Int) {
        // Notification tap means a status changed on the server — never trust the local cache.
        // Always set pending and trigger a fresh fetch so the detail shows the latest status.
        pendingNavigationOrderID = orderID
        if lastCustomerId > 0 {
            service.onFetchHistoryOrders()
        } else if let order = orders.first(where: { $0.id == orderID }) {
            // Cold-start fallback: no customerId yet — show cached order; MyOrdersView.onAppear will refresh
            selectedOrder = order
            showHistoryOrderDetail = true
        }
    }

    private func resolvePendingNavigation() {
        guard let orderID = pendingNavigationOrderID,
              let order = orders.first(where: { $0.id == orderID }) else { return }
        pendingNavigationOrderID = nil
        selectedOrder = order
        showHistoryOrderDetail = true
    }

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
}

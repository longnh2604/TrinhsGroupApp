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

    private var service: HistoryServices = HistoryServices()
    private var cancellableSet: Set<AnyCancellable> = []
    // Holds an order_id from a notification tap that arrived before orders were loaded
    private var pendingNavigationOrderID: Int?
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
    }

    func fetchOrders(customerId: Int) {
        lastCustomerId = customerId
        service.onFetchHistoryOrders()
    }

    func cancelOrder(orderID: Int) {
        isCancelling = true
        service.onCancelOrder(orderID: orderID)
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
}

//
//  HistoryServices.swift
//  TrinhsGroup
//
//  Created by long on 22/07/2022.
//

import Foundation
import Combine
import SwiftyJSON

protocol HistoryServicesProtocol: BaseServiceProtocol {
    var historyOrdersPublisher: AnyPublisher<[Order], Never> { get }
}

class HistoryServices: HistoryServicesProtocol {
    public private(set) lazy var historyOrdersPublisher: AnyPublisher<[Order], Never> = $orders.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    private let cancelOrderSubject = PassthroughSubject<Order, Never>()
    private let cancelErrorSubject = PassthroughSubject<String, Never>()
    public lazy var cancelOrderPublisher: AnyPublisher<Order, Never> = cancelOrderSubject.eraseToAnyPublisher()
    public lazy var cancelErrorPublisher: AnyPublisher<String, Never> = cancelErrorSubject.eraseToAnyPublisher()

    /// Carries the order ID alongside the result so a late response for an order the user
    /// has already navigated away from can be discarded instead of overwriting the rail.
    private let orderHistorySubject = PassthroughSubject<(orderID: Int, history: OrderStatusHistory?), Never>()
    public lazy var orderHistoryPublisher: AnyPublisher<(orderID: Int, history: OrderStatusHistory?), Never> =
        orderHistorySubject.eraseToAnyPublisher()

    private var cancellableSet: Set<AnyCancellable> = []
    private let api = WooCommerceAPI()

    @Published private var isLoading: Bool = false
    @Published private var error: String = ""
    @Published var orders = [Order]()

    /// Orders for the signed-in customer. The server derives the customer from the JWT —
    /// the previous `?customer=<id>` query could list any customer's order history.
    func onFetchHistoryOrders() {
        self.isLoading.toggle()
        api.request(endpoint: .myOrders, method: .GET) { (result: Result<[Order], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.orders = data
                case .failure(let error):
                    self.error = error.localizedDescription
                }
                self.isLoading.toggle()
            }
        }
    }

    /// Status timeline for one order.
    ///
    /// Deliberately routes neither through `loadingPublisher` nor `errorPublisher`:
    ///
    /// - `isLoading` drives a full-screen spinner; this is a secondary fetch that decorates
    ///   an already-visible screen.
    /// - `errorPublisher` is wired in `HistoryViewModel` to set `message` and tear down the
    ///   notification-tap spinner. A 404 here — which is what a server that predates this
    ///   endpoint returns — would pop a "Couldn't Open Order" alert over a perfectly good
    ///   order detail screen.
    ///
    /// A failure publishes `nil`, and the rail falls back to `date_created` /
    /// `date_modified`.
    func onFetchOrderStatusHistory(orderID: Int) {
        api.request(endpoint: .myOrderHistory(orderID: orderID), method: .GET) { [weak self] (result: Result<OrderStatusHistory, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let history):
                    self?.orderHistorySubject.send((orderID: orderID, history: history))
                case .failure(let error):
                    print("ℹ️ No status history for order \(orderID): \(error.localizedDescription)")
                    self?.orderHistorySubject.send((orderID: orderID, history: nil))
                }
            }
        }
    }

    /// Cancels one of the caller's own orders. The server verifies ownership and refuses
    /// orders that are already paid or fulfilled.
    func onCancelOrder(orderID: Int) {
        api.request(
            endpoint: .cancelMyOrder(orderID: orderID),
            method: .POST
        ) { [weak self] (result: Result<Order, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let updated):
                    self?.cancelOrderSubject.send(updated)
                case .failure(let error):
                    self?.cancelErrorSubject.send(error.localizedDescription)
                }
            }
        }
    }
}

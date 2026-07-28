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

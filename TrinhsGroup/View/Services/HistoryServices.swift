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

    private var cancellableSet: Set<AnyCancellable> = []
    private let api = WooCommerceAPI()
    
    @Published private var isLoading: Bool = false
    @Published private var error: String = ""
    @Published var orders = [Order]()
    
    func onFetchHistoryOrders(id: Int) {
        self.isLoading.toggle()
        api.request(endpoint: .fetchHistoryOrders(customerID: id), method: .GET) { (result: Result<[Order], Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print("All orders: \(data)")
                    self.orders = data
                case .failure(let error):
                    print("Error failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
                self.isLoading.toggle()
            }
        }
    }
}

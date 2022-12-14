//
//  HistoryServices.swift
//  TrinhsGroup
//
//  Created by long on 22/07/2022.
//

import Combine

protocol HistoryServicesProtocol: BaseServiceProtocol {
    var historyOrdersPublisher: AnyPublisher<[Order], Never> { get }
}

class HistoryServices: HistoryServicesProtocol {
    public private(set) lazy var historyOrdersPublisher: AnyPublisher<[Order], Never> = $orders.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    private var cancellableSet: Set<AnyCancellable> = []
    @Published private var isLoading: Bool = false
    @Published private var error: String = ""
    @Published var orders = [Order]()
    
    func onFetchHistoryOrders(id: Int) {
        self.isLoading.toggle()
        APIClient.shared.onFetchHistoryOrders(id: id) { success, data, error in
            if success {
                if let data = data as? [Order] {
                    self.orders = data
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        }
    }
}

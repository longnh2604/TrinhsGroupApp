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
    @Published var showHistory = false
    @Published var showHistoryOrderDetail = false
    @Published var showLoading = false
    @Published var message: String = ""
    
    private var service: HistoryServices = HistoryServices()
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(service: HistoryServices = HistoryServices()) {
        self.service = service
        self.bindingData()
    }
    
    func bindingData() {
        service.loadingPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .assign(to: &$showLoading)
        
        service.errorPublisher
            .receive(on: RunLoop.main)
            .sink { error in
                self.message = error
            }
            .store(in: &cancellableSet)
        
        service.historyOrdersPublisher
            .receive(on: RunLoop.main)
            .assign(to: &$orders)
    }
    
    func fetchOrders(customerId: Int) {
        service.onFetchHistoryOrders(id: customerId)
    }
}

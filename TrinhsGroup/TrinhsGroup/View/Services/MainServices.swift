//
//  MainServices.swift
//  TrinhsGroup
//
//  Created by long on 12/07/2022.
//

import SwiftyJSON
import Combine

protocol MainServicesProtocol: BaseServiceProtocol {
    var categoryPublisher: AnyPublisher<[Category], Never> { get }
    var selectedCategoryProductPublisher: AnyPublisher<[Product], Never> { get }
    var loginPublisher: AnyPublisher<Bool, Never> { get }
}

class MainServices: MainServicesProtocol {
    public private(set) lazy var categoryPublisher: AnyPublisher<[Category], Never> = $categories.eraseToAnyPublisher()
    public private(set) lazy var selectedCategoryProductPublisher: AnyPublisher<[Product], Never> = $selectedCategoryProducts.eraseToAnyPublisher()
    public private(set) lazy var loginPublisher: AnyPublisher<Bool, Never> = $isLoggedIn.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    private var cancellableSet: Set<AnyCancellable> = []
    @Published private var isLoading: Bool = false
    @Published private var isLoggedIn: Bool = false
    @Published private var isUpdated: Bool = false
    @Published private var error: String = ""
    @Published var categories = [Category]()
    @Published var selectedCategoryProducts = [Product]()
    
    func onFetchCategories() {
        self.isLoading.toggle()
        APIClient.shared.onFetchCategories(completion: { success, data, error in
            if success {
                if let data = data as? [Category] {
                    self.categories = data
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        })
    }
    
    func fetchSelectedCategoryProducts(id: Int) {
        self.isLoading.toggle()
        APIClient.shared.onFetchSelectedCategoryProducts(id: id) { success, data, error in
            if success {
                if let data = data as? [Product] {
                    self.selectedCategoryProducts = data
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        }
    }
}

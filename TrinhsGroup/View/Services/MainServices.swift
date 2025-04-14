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
    var orderReceivedPublisher: AnyPublisher<Order, Never> { get }
    var loginPublisher: AnyPublisher<Bool, Never> { get }
    var popularProductsPublisher: AnyPublisher<[Product], Never> { get }
}

class MainServices: MainServicesProtocol {
    public private(set) lazy var categoryPublisher: AnyPublisher<[Category], Never> = $categories.eraseToAnyPublisher()
    public private(set) lazy var popularProductsPublisher: AnyPublisher<[Product], Never> = $popularProducts.eraseToAnyPublisher()
    public private(set) lazy var selectedCategoryProductPublisher: AnyPublisher<[Product], Never> = $selectedCategoryProducts.eraseToAnyPublisher()
    public private(set) lazy var orderReceivedPublisher: AnyPublisher<Order, Never> = $orderReceived.eraseToAnyPublisher()
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
    @Published var popularProducts = [Product]()
    @Published var orderReceived = Order.default
    
    private let api = WooCommerceAPI()
    
    func onFetchCategories() {
        self.isLoading.toggle()
        api.request(endpoint: .fetchCategories, method: .GET) { (result: Result<[Category], Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print(data)
                    self.categories = data
                case .failure(let error):
                    print("Error failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func onFetchPopularProducts() {
        self.isLoading.toggle()
        api.request(endpoint: .fetchPopularProducts, method: .GET) { (result: Result<[Product], Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print(data)
                    self.popularProducts = data
                case .failure(let error):
                    print("Error failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func fetchSelectedCategoryProducts(id: Int) {
        self.isLoading.toggle()
        api.request(endpoint: .fetchProductsCategory(categoryID: id), method: .GET) { (result: Result<[Product], Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print(data)
                    self.selectedCategoryProducts = data
                case .failure(let error):
                    print("Error failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func onCreateOrder(user: User, paymentMethod: String, paymentMethodTitle: String, customerNote: String, status: String, productOrders: [ProductOrder]) {
        self.isLoading.toggle()
        APIClient.shared.onCreateOrder(user: user, paymentMethod: paymentMethod, paymentMethodTitle: paymentMethodTitle, customerNote: customerNote, status: status, productOrders: productOrders) { success, data, error in
            if success {
                if let data = data as? Order {
                    self.orderReceived = data
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        }
    }
}

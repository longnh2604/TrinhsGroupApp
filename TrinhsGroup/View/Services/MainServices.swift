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
    var orderPublisher: AnyPublisher<Order, Never> { get }
    var loginPublisher: AnyPublisher<Bool, Never> { get }
    var popularProductsPublisher: AnyPublisher<[Product], Never> { get }
    var paymentMethodPublisher: AnyPublisher<[Payment], Never> { get }
    var categoryProductsLoadingPublisher: AnyPublisher<Bool, Never> { get }
}

class MainServices: MainServicesProtocol {
    public private(set) lazy var categoryPublisher: AnyPublisher<[Category], Never> = $categories.eraseToAnyPublisher()
    public private(set) lazy var popularProductsPublisher: AnyPublisher<[Product], Never> = $popularProducts.eraseToAnyPublisher()
    public private(set) lazy var selectedCategoryProductPublisher: AnyPublisher<[Product], Never> = $selectedCategoryProducts.eraseToAnyPublisher()
    public private(set) lazy var orderPublisher: AnyPublisher<Order, Never> = $order.eraseToAnyPublisher()
    public private(set) lazy var paymentMethodPublisher: AnyPublisher<[Payment], Never> = $payments.eraseToAnyPublisher()
    public private(set) lazy var loginPublisher: AnyPublisher<Bool, Never> = $isLoggedIn.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()
    public private(set) lazy var categoryProductsLoadingPublisher: AnyPublisher<Bool, Never> = $isCategoryProductsLoading.eraseToAnyPublisher()

    private var cancellableSet: Set<AnyCancellable> = []
    @Published private var isLoading: Bool = false
    @Published private var isCategoryProductsLoading: Bool = false
    @Published private var isLoggedIn: Bool = false
    @Published private var isUpdated: Bool = false
    @Published private var error: String = ""
    @Published var categories = [Category]()
    @Published var selectedCategoryProducts = [Product]()
    @Published var popularProducts = [Product]()
    @Published var order = Order.default
    @Published var payments = [Payment]()
    
    private let api = WooCommerceAPI()
    
    // Helper function to convert AnyCodableValue to JSON-serializable value
    private func convertAnyCodableValueToJSON(_ value: AnyCodableValue) -> Any {
        switch value {
        case .integer(let intValue):
            return intValue
        case .string(let stringValue):
            return stringValue
        case .float(let floatValue):
            return floatValue
        case .double(let doubleValue):
            return doubleValue
        case .boolean(let boolValue):
            return boolValue
        case .null:
            return NSNull()
        }
    }
    
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
        self.isCategoryProductsLoading = true
        api.request(endpoint: .fetchProductsCategory(categoryID: id), method: .GET) { (result: Result<[Product], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    print(data)
                    self.selectedCategoryProducts = data
                case .failure(let error):
                    print("Error failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
                self.isCategoryProductsLoading = false
            }
        }
    }
    
    func onCreateOrder(
        user: User,
        paymentMethod: String,
        paymentMethodTitle: String,
        customerNote: String,
        status: String,
        productOrders: [ProductOrder],
        pickupDateTime: String,
        discountValue: Double,
        completion: @escaping (_ orderId: Int?, _ paymentURL: String?) -> Void
    ) {
        self.isLoading = true

        var lineItems: [[String: Any]] = []
        for p in productOrders {
            var metas: [[String: Any]] = []
            for m in p.meta_data {
                // Convert AnyCodableValue to JSON-serializable value
                let jsonValue: Any = convertAnyCodableValueToJSON(m.value)
                metas.append(["id": m.id, "key": m.key, "value": jsonValue])
            }
            lineItems.append([
                "product_id": p.product_id,
                "quantity": p.quantity,
                "meta_data": metas
                // Woo can compute totals; if you must send total, keep it as a String.
                // "total": "\(p.price)"
            ])
        }

        // Parse pickup datetime to separate date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        
        var pickupDate = ""
        var pickupTime = ""
        
        if let date = dateFormatter.date(from: pickupDateTime) {
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "Y-m-d"
            dateOnlyFormatter.timeZone = TimeZone(identifier: "Australia/Sydney")
            pickupDate = dateOnlyFormatter.string(from: date)
            
            let timeOnlyFormatter = DateFormatter()
            timeOnlyFormatter.dateFormat = "H:i"
            timeOnlyFormatter.timeZone = TimeZone(identifier: "Australia/Sydney")
            pickupTime = timeOnlyFormatter.string(from: date)
        }

        var json: [String: Any] = [
            "customer_id": user.id,
            "set_paid": false,
            "payment_method": paymentMethod,            // e.g. "stripe"
            "payment_method_title": paymentMethodTitle,
            "customer_note": customerNote,
            // Consider "pending" for unpaid orders; "on-hold" also works.
            "status": status,
            "billing": [
                "first_name": user.billing.first_name,
                "last_name": user.billing.last_name,
                "country": user.billing.country,
                "address_1": user.billing.address_1,
                "city": user.billing.city,
                "postcode": user.billing.postcode,
                "state": user.billing.state,
                "email": user.billing.email,
                "phone": user.billing.phone
            ],
            "line_items": lineItems,
            "meta_data": [
                [
                    "key": "pickup_datetime",
                    "value": pickupDateTime
                ]
            ]
        ]

        // Apply 5% discount as a negative fee line so order total reflects discount
        if discountValue > 0 {
            let feeLines: [[String: Any]] = [[
                "name": "Discount 5%",
                "total": String(format: "-%.2f", discountValue)
            ]]
            json["fee_lines"] = feeLines
        }

        api.request(endpoint: .onCreateOrder, method: .POST, body: json) { (result: Result<Order, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let order):
                    self.order = order
                    completion(order.id, order.paymentURL)
                case .failure(let error):
                    self.error = error.localizedDescription
                    completion(nil, nil)
                }
            }
        }
    }
    
    func onFetchPaymentMethods() {
        self.isLoading.toggle()
        api.request(endpoint: .fetchPaymentMethods, method: .GET) { (result: Result<[Payment], Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print("✅ Payment methods fetched successfully")
                    print("📦 Total payment methods received: \(data.count)")
                    print("📋 All payments: \(data)")
                    
                    // Filter to get only enabled payments
                    let enabledPayments = data.filter { $0.enabled }
                    print("✅ Enabled payments count: \(enabledPayments.count)")
                    print("📋 Enabled payments: \(enabledPayments)")
                    
                    // Log each payment method details
                    for payment in enabledPayments {
                        print("  - ID: \(payment.id), Title: \(payment.title), Enabled: \(payment.enabled)")
                    }
                    
                    self.payments = enabledPayments
                    
                    if enabledPayments.isEmpty {
                        print("⚠️ Warning: No enabled payment methods found!")
                        self.error = "No payment methods available"
                    }
                case .failure(let error):
                    print("❌ Error fetching payment methods: \(error.localizedDescription)")
                    
                    // Try to get more details about the error
                    if let decodingError = error as? DecodingError {
                        print("🔍 Decoding error details:")
                        switch decodingError {
                        case .typeMismatch(let type, let context):
                            print("  Type mismatch: \(type) at \(context.codingPath)")
                        case .valueNotFound(let type, let context):
                            print("  Value not found: \(type) at \(context.codingPath)")
                        case .keyNotFound(let key, let context):
                            print("  Key not found: \(key.stringValue) at \(context.codingPath)")
                        case .dataCorrupted(let context):
                            print("  Data corrupted at \(context.codingPath)")
                        @unknown default:
                            print("  Unknown decoding error")
                        }
                    }
                    
                    self.error = error.localizedDescription
                    self.payments = [] // Clear payments on error
                }
            }
        }
    }
}

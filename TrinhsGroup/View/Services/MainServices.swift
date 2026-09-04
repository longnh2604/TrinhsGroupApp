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
        // FB-7. Spans exactly the time MenuView shows its spinner, so the trace is the wait
        // the customer sees rather than the request alone.
        let trace = AppTrace(AppTrace.Name.menuLoad)
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
                // From `result`, not `self.error` — that property keeps the last error the
                // service ever saw, so a success after any earlier failure would be tagged
                // as a failure.
                trace.stop(success: (try? result.get()) != nil)
            }
        }
    }
    
    /// The `line_items` payload, shared by ordering and quoting so the price the customer is
    /// shown and the price they are charged are built from one description of the basket.
    ///
    /// `yith_wapo` is what actually buys the add-ons: the server hands it to YITH, which prices
    /// the line and writes the choice the kitchen reads. `meta_data` still carries the note.
    private func lineItemsPayload(from productOrders: [ProductOrder]) -> [[String: Any]] {
        productOrders.map { p in
            var metas: [[String: Any]] = []
            for m in p.meta_data {
                let jsonValue: Any = convertAnyCodableValueToJSON(m.value)
                var meta: [String: Any] = ["key": m.key, "value": jsonValue]
                if let id = m.id { meta["id"] = id }
                metas.append(meta)
            }

            var line: [String: Any] = [
                "product_id": p.product_id,
                "quantity": p.quantity,
                "meta_data": metas
            ]

            let pairs = p.addOnChoices.submitPairs
            if !pairs.isEmpty {
                line["yith_wapo"] = pairs
            }

            return line
        }
    }

    /// Add-on groups for one product, from YITH by way of trinh-app-api.
    ///
    /// Handed back through a completion rather than published on this service, on purpose: the
    /// Firestore add-ons it replaces lived on a shared manager keyed by category, so opening a
    /// second product in the same category inherited the first one's ticks. These belong to the
    /// screen that asked for them.
    func fetchAddOnGroups(productId: Int, completion: @escaping (Result<[AddOnGroup], Error>) -> Void) {
        api.request(endpoint: .productAddOns(productID: productId), method: .GET) { (result: Result<AddOnGroupsResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    completion(.success(response.addons))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// What this basket would cost, priced by the server, without creating an order.
    ///
    /// The payment method is part of the question, not decoration: the 5% cash-on-pickup
    /// discount is a negative gateway fee, so the total depends on which gateway is chosen.
    func fetchOrderQuote(
        paymentMethod: String,
        productOrders: [ProductOrder],
        couponCode: String? = nil,
        completion: @escaping (Result<OrderQuote, Error>) -> Void
    ) {
        var json: [String: Any] = [
            "payment_method": paymentMethod,
            "line_items": lineItemsPayload(from: productOrders)
        ]

        if let couponCode = couponCode, !couponCode.isEmpty {
            json["coupon_code"] = couponCode
        }

        // FB-7. The basket total is priced server-side, so this sits between the customer
        // changing the order and the price updating — a wait worth watching.
        let trace = AppTrace(AppTrace.Name.orderPreview)
        api.request(endpoint: .orderQuote, method: .POST, body: json) { (result: Result<OrderQuote, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let quote):
                    trace.stop(success: true)
                    completion(.success(quote))
                case .failure(let error):
                    trace.stop(success: false)
                    completion(.failure(error))
                }
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
        couponCode: String? = nil,
        completion: @escaping (_ orderId: Int?, _ paymentURL: String?) -> Void
    ) {
        self.isLoading = true

        let lineItems = lineItemsPayload(from: productOrders)

        // The pickup date/time used to be split apart here into the CodeRockz plugin's
        // _pi_delivery_* meta keys. The server now derives those from the raw
        // `pickup_datetime` string (see trinh_app_pickup_meta in trinh-app-api), so this
        // parsing had become dead — the two locals were assigned and never read.

        // Use user.email as fallback if billing.email is empty
        let billingEmail = user.billing.email.isEmpty ? user.email : user.billing.email
        let billingFirstName = user.billing.first_name.isEmpty ? user.first_name : user.billing.first_name
        let billingLastName = user.billing.last_name.isEmpty ? user.last_name : user.billing.last_name
        
        // Validate email before sending
        guard !billingEmail.isEmpty else {
            print("❌ Error: No valid email address found for user")
            self.isLoading = false
            self.error = "No valid email address found. Please update your profile."
            completion(nil, nil)
            return
        }
        
        // customer_id and set_paid are deliberately absent: the server forces both from
        // the JWT so an order can never be filed against another account or self-marked
        // as paid. No price is sent either — the server builds a real WooCommerce cart, so
        // YITH prices the add-ons and the 5% cash-on-pickup discount arrives as the gateway
        // fee the website is configured with. POST /me/orders/preview quotes the same cart.
        var json: [String: Any] = [
            "payment_method": paymentMethod,            // e.g. "stripe"
            "payment_method_title": paymentMethodTitle,
            "customer_note": customerNote,
            // Server allowlists this to "pending" or "on-hold".
            "status": status,
            "billing": [
                "first_name": billingFirstName,
                "last_name": billingLastName,
                "country": user.billing.country.isEmpty ? "AU" : user.billing.country,
                "address_1": user.billing.address_1,
                "city": user.billing.city,
                "postcode": user.billing.postcode,
                "state": user.billing.state,
                "email": billingEmail,
                "phone": user.billing.phone
            ],
            "line_items": lineItems,
            "pickup_datetime": pickupDateTime
        ]

        // The server checks the voucher belongs to this account before applying it.
        if let couponCode = couponCode, !couponCode.isEmpty {
            json["coupon_code"] = couponCode
        }

        // FB-7. Started here rather than at the top of the method so the early return on a
        // missing billing email cannot leave a trace running forever.
        let trace = AppTrace(AppTrace.Name.orderSubmit)
        api.request(endpoint: .myOrders, method: .POST, body: json) { (result: Result<Order, Error>) in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let order):
                    self.order = order
                    trace.stop(success: true)
                    completion(order.id, order.paymentURL)
                case .failure(let error):
                    self.error = error.localizedDescription
                    trace.stop(success: false)
                    completion(nil, nil)
                }
            }
        }
    }
    
    func onFetchPaymentMethods() {
        self.isLoading.toggle()
        api.request(endpoint: .paymentMethods, method: .GET) { (result: Result<[Payment], Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print("✅ Payment methods fetched successfully")
                    print("📦 Total payment methods received: \(data.count)")
                    print("📋 All payments: \(data)")
                    
                    // Filter to standalone enabled gateways only.
                    // Exclude sub-method prefixes: woocommerce_payments_* (Apple/Google Pay express
                    // methods) and stripe_* (Link, SEPA, etc.) — these are handled inside their
                    // parent gateway's own checkout, not shown as separate options.
                    let enabledPayments = data.filter {
                        $0.enabled &&
                        !$0.title.isEmpty &&
                        !$0.id.hasPrefix("woocommerce_payments_") &&
                        !$0.id.hasPrefix("stripe_")
                    }
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

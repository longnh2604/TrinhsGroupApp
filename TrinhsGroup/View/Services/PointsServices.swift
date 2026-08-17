import Foundation
import Combine

protocol PointsServicesProtocol: BaseServiceProtocol {
    var pointsPublisher: AnyPublisher<PointsResponse?, Never> { get }
    var redeemPublisher: AnyPublisher<RedeemResponse?, Never> { get }
    var vouchersPublisher: AnyPublisher<[VoucherResponse], Never> { get }
    var allVouchersPublisher: AnyPublisher<[VoucherResponse], Never> { get }
    var redeemErrorPublisher: AnyPublisher<String, Never> { get }
    func fetchMyPoints(userId: Int)
    func redeemPoints(userId: Int, points: Int)
    func fetchVouchers(userId: Int)
    func fetchAllVouchers(userId: Int)
}

final class PointsServices: PointsServicesProtocol {
    public private(set) lazy var pointsPublisher: AnyPublisher<PointsResponse?, Never> = $points.eraseToAnyPublisher()
    public private(set) lazy var redeemPublisher: AnyPublisher<RedeemResponse?, Never> = $redeemResponse.eraseToAnyPublisher()
    public private(set) lazy var vouchersPublisher: AnyPublisher<[VoucherResponse], Never> = $vouchers.eraseToAnyPublisher()
    public private(set) lazy var allVouchersPublisher: AnyPublisher<[VoucherResponse], Never> = $allVouchers.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    /// Failures while *reading* points. Kept separate from `redeemErrorPublisher` so the UI
    /// can title the alert accurately — a failed balance load is not a failed redemption.
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    private let redeemErrorSubject = PassthroughSubject<String, Never>()
    /// Failures of an explicit redeem action the user initiated.
    public lazy var redeemErrorPublisher: AnyPublisher<String, Never> = redeemErrorSubject.eraseToAnyPublisher()

    @Published private var isLoading: Bool = false
    @Published private var error: String = ""
    @Published private var points: PointsResponse?
    @Published private var redeemResponse: RedeemResponse?
    @Published private var vouchers: [VoucherResponse] = []
    @Published private var allVouchers: [VoucherResponse] = []
    
    private let api = WooCommerceAPI()

    /// Fetch the signed-in customer's myCred balance.
    ///
    /// Reads `bu/v1/me/points` rather than scraping `meta_data` off the customer record:
    /// WooCommerce only includes `meta_data` in the customers response for administrators
    /// (class-wc-rest-customers-v2-controller.php:82), so that key disappeared once the
    /// app started authenticating as the customer instead of via an admin consumer key.
    ///
    /// - Note: `userId` is ignored — the account comes from the JWT, and trinh-api-guard
    ///   fills in the route's `user_id` server-side.
    func fetchMyPoints(userId: Int) {
        isLoading = true
        error = ""

        print("🔵 Points API Request: fetching own balance")

        api.request(endpoint: .myPoints, method: .GET) { [weak self] (result: Result<PointsResponse, Error>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let response):
                    self.points = response
                    print("✅ Points fetched successfully: \(response.balance)")

                case .failure(let error):
                    print("❌ Points API Error: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    /// Redeem points for a voucher using the custom myCred plugin API
    /// POST /wp-json/bu/v1/redeem
    /// 1 point = $1, minimum 10 points to redeem
    func redeemPoints(userId: Int, points: Int) {
        guard userId > 0 else {
            redeemErrorSubject.send("Invalid user account")
            return
        }

        guard points >= 10 && points % 10 == 0 else {
            redeemErrorSubject.send("Points must be at least 10 and in increments of 10")
            return
        }

        isLoading = true

        print("🔵 Redeem API Request: Redeeming \(points) points for user \(userId)")
        
        // user_id is deliberately omitted — trinh-api-guard (mu-plugin) forces it to the
        // JWT's own user, so points can only ever be redeemed from the caller's balance.
        let body: [String: Any] = [
            "points": points
        ]

        api.request(endpoint: .redeemPoints, method: .POST, body: body) { [weak self] (result: Result<RedeemResponse, Error>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let redeemResult):
                    print("✅ Redeem successful: Coupon \(redeemResult.couponCode) for $\(redeemResult.amount)")
                    self.redeemResponse = redeemResult
                    // Update the local points balance
                    self.points = PointsResponse(userId: userId, type: "mycred_default", balance: redeemResult.balance)
                    
                case .failure(let error):
                    print("❌ Redeem API Error: \(error.localizedDescription)")
                    // Try to parse specific error messages
                    if let wooError = error as? WooErrorResponse {
                        self.redeemErrorSubject.send(wooError.message)
                    } else {
                        self.redeemErrorSubject.send(self.parseRedeemError(error.localizedDescription))
                    }
                }
            }
        }
    }
    
    /// Parse redeem error messages into user-friendly text
    private func parseRedeemError(_ errorString: String) -> String {
        if errorString.contains("invalid_user_id") {
            return "Invalid user account"
        } else if errorString.contains("invalid_points") {
            return "Invalid points amount"
        } else if errorString.contains("points_not_allowed") {
            return "Points must be at least 10 and in increments of 10"
        } else if errorString.contains("insufficient_points") {
            return "Insufficient points for this redemption"
        } else if errorString.contains("coupon_create_failed") {
            return "Failed to create voucher. Please try again."
        } else if errorString.contains("mycred_not_available") {
            return "Points system unavailable"
        } else if errorString.contains("woocommerce_not_available") {
            return "Store system unavailable"
        }
        return errorString
    }
    
    /// Fetch the signed-in customer's currently usable vouchers.
    ///
    /// GET /wp-json/trinh-app/v1/me/vouchers returns only this account's redeemed
    /// vouchers. The old path pulled every coupon in the store and filtered by an
    /// "RW{userId}-" code prefix on the device, which handed all store-wide promo codes
    /// to every customer.
    ///
    /// - Note: `userId` is now ignored — the account comes from the JWT. Passing a
    ///   different id will not return another customer's vouchers.
    func fetchVouchers(userId: Int) {
        api.request(endpoint: .myVouchers, method: .GET) { [weak self] (result: Result<[WCCouponResponse], Error>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let coupons):
                    print("✅ Vouchers fetched: \(coupons.count) for this account")
                    self.vouchers = coupons
                        .filter { $0.isValid }
                        .map { $0.toVoucherResponse() }
                    print("✅ User vouchers: \(self.vouchers.count) available")

                case .failure(let error):
                    print("❌ Vouchers API Error: \(error.localizedDescription)")
                    self.vouchers = []
                }
            }
        }
    }

    /// Fetch ALL of the user's redeemed vouchers, including used and expired ones.
    /// Unlike `fetchVouchers` (which returns only currently-usable vouchers for checkout),
    /// this keeps the full history so the wallet screen can show Available and History.
    ///
    /// - Note: `userId` is now ignored — the account comes from the JWT.
    func fetchAllVouchers(userId: Int) {
        api.request(endpoint: .myVouchers, method: .GET) { [weak self] (result: Result<[WCCouponResponse], Error>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let coupons):
                    self.allVouchers = coupons
                        .map { $0.toVoucherResponse() }
                        .sorted { ($0.expirationDate ?? .distantPast) > ($1.expirationDate ?? .distantPast) }

                case .failure(let error):
                    print("❌ All Vouchers API Error: \(error.localizedDescription)")
                    self.allVouchers = []
                }
            }
        }
    }
}

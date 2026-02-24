import Foundation
import Combine

protocol PointsServicesProtocol: BaseServiceProtocol {
    var pointsPublisher: AnyPublisher<PointsResponse?, Never> { get }
    var redeemPublisher: AnyPublisher<RedeemResponse?, Never> { get }
    var vouchersPublisher: AnyPublisher<[VoucherResponse], Never> { get }
    func fetchMyPoints(userId: Int)
    func redeemPoints(userId: Int, points: Int)
    func fetchVouchers(userId: Int)
}

final class PointsServices: PointsServicesProtocol {
    public private(set) lazy var pointsPublisher: AnyPublisher<PointsResponse?, Never> = $points.eraseToAnyPublisher()
    public private(set) lazy var redeemPublisher: AnyPublisher<RedeemResponse?, Never> = $redeemResponse.eraseToAnyPublisher()
    public private(set) lazy var vouchersPublisher: AnyPublisher<[VoucherResponse], Never> = $vouchers.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    @Published private var isLoading: Bool = false
    @Published private var error: String = ""
    @Published private var points: PointsResponse?
    @Published private var redeemResponse: RedeemResponse?
    @Published private var vouchers: [VoucherResponse] = []
    
    private let api = WooCommerceAPI()

    /// Fetch points for a specific user ID using WooCommerce Customer API
    /// Points are stored in meta_data with key "mycred_default"
    func fetchMyPoints(userId: Int) {
        guard userId > 0 else {
            self.error = "Invalid user ID"
            return
        }
        
        isLoading = true
        error = ""

        print("🔵 Points API Request: Fetching customer \(userId) for points")

        api.request(endpoint: .specificCustomer(customerID: userId), method: .GET) { [weak self] (result: Result<WooCustomerPointsResponse, Error>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let customerResponse):
                    let balance = customerResponse.getMyCreditPoints()
                    self.points = PointsResponse(userId: userId, type: "mycred_default", balance: balance)
                    print("✅ Points fetched successfully: \(balance)")
                    
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
            self.error = "Invalid user ID"
            return
        }
        
        guard points >= 10 && points % 10 == 0 else {
            self.error = "Points must be at least 10 and in increments of 10"
            return
        }
        
        isLoading = true
        error = ""
        
        print("🔵 Redeem API Request: Redeeming \(points) points for user \(userId)")
        
        let body: [String: Any] = [
            "user_id": userId,
            "points": points
        ]
        
        // Use requestWithoutAuth for custom bu/v1 endpoint (no WooCommerce auth needed)
        api.requestWithoutAuth(endpoint: .redeemPoints, method: .POST, body: body) { [weak self] (result: Result<RedeemResponse, Error>) in
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
                        self.error = wooError.message
                    } else {
                        self.error = self.parseRedeemError(error.localizedDescription)
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
    
    /// Fetch user's available vouchers/coupons from WooCommerce Coupons API
    /// GET /wp-json/wc/v3/coupons
    /// Filters coupons that start with "RW{userId}-" prefix (redeemed vouchers)
    func fetchVouchers(userId: Int) {
        guard userId > 0 else {
            self.error = "Invalid user ID"
            print("❌ Vouchers API Error: Invalid user ID (\(userId))")
            return
        }
        
        print("🔵 Vouchers API Request: Fetching WooCommerce coupons for user \(userId)")
        print("🌐 Endpoint: /wp-json/wc/v3/coupons")
        
        // Use WooCommerce API with auth to fetch all coupons
        api.request(endpoint: .wcCoupons, method: .GET) { [weak self] (result: Result<[WCCouponResponse], Error>) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let coupons):
                    print("✅ WC Coupons fetched: \(coupons.count) total coupons")
                    
                    // Filter coupons for this user (prefix "RW{userId}-") and valid ones
                    let userPrefix = "rw\(userId)-"
                    let userCoupons = coupons.filter { coupon in
                        let isUserCoupon = coupon.code.lowercased().hasPrefix(userPrefix)
                        let isValid = coupon.isValid
                        print("  📦 Coupon: \(coupon.code) - $\(coupon.amount) - Valid: \(isValid) - IsUser: \(isUserCoupon)")
                        return isUserCoupon && isValid
                    }
                    
                    // Convert to VoucherResponse for UI
                    self.vouchers = userCoupons.map { $0.toVoucherResponse() }
                    print("✅ User vouchers: \(self.vouchers.count) available")
                    
                case .failure(let error):
                    print("❌ WC Coupons API Error: \(error.localizedDescription)")
                    print("❌ Full error: \(error)")
                    self.vouchers = []
                }
            }
        }
    }
}

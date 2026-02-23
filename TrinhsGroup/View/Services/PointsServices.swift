import Foundation
import Combine

protocol PointsServicesProtocol: BaseServiceProtocol {
    var pointsPublisher: AnyPublisher<PointsResponse?, Never> { get }
    func fetchMyPoints(userId: Int)
}

final class PointsServices: PointsServicesProtocol {
    public private(set) lazy var pointsPublisher: AnyPublisher<PointsResponse?, Never> = $points.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    @Published private var isLoading: Bool = false
    @Published private var error: String = ""
    @Published private var points: PointsResponse?
    
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
}

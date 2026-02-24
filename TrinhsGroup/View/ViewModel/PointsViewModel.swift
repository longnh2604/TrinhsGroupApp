import Foundation
import Combine

final class PointsViewModel: ObservableObject {
    @Published var balance: Double?
    @Published var isLoading: Bool = false
    @Published var message: String = ""
    @Published var lastRedeemResponse: RedeemResponse?
    @Published var showRedeemSuccess: Bool = false
    @Published var showRedeemError: Bool = false
    @Published var availableVouchers: [VoucherResponse] = []
    @Published var isLoadingVouchers: Bool = false

    private var service: PointsServices = PointsServices()
    private var cancellableSet: Set<AnyCancellable> = []

    init(service: PointsServices = PointsServices()) {
        self.service = service
        bindingData()
    }

    private func bindingData() {
        service.loadingPublisher
            .receive(on: RunLoop.main)
            .assign(to: &$isLoading)

        service.errorPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] err in
                guard let self = self else { return }
                self.message = err
                if !err.isEmpty {
                    self.showRedeemError = true
                }
            }
            .store(in: &cancellableSet)

        service.pointsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] points in
                self?.balance = points?.balance
            }
            .store(in: &cancellableSet)
        
        service.redeemPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] response in
                guard let self = self, let response = response else { return }
                self.lastRedeemResponse = response
                self.balance = response.balance
                self.showRedeemSuccess = true
            }
            .store(in: &cancellableSet)
        
        service.vouchersPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] vouchers in
                self?.availableVouchers = vouchers
                self?.isLoadingVouchers = false
            }
            .store(in: &cancellableSet)
    }

    func fetchPoints(userId: Int) {
        guard userId > 0 else {
            self.message = "Invalid user ID"
            return
        }
        service.fetchMyPoints(userId: userId)
    }
    
    /// Check if user has enough points to redeem for a specific amount
    /// 1 point = $1, minimum 10 points to redeem
    func canRedeem(points: Int) -> Bool {
        guard let currentBalance = balance else { return false }
        return Int(currentBalance) >= points && points >= 10 && points % 10 == 0
    }
    
    /// Redeem points for a voucher
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - points: Number of points to redeem (must be >= 10 and divisible by 10)
    func redeemPoints(userId: Int, points: Int) {
        guard userId > 0 else {
            self.message = "Invalid user ID"
            self.showRedeemError = true
            return
        }
        
        guard canRedeem(points: points) else {
            if let currentBalance = balance, Int(currentBalance) < points {
                self.message = "Insufficient points. You need \(points) points but only have \(Int(currentBalance))."
            } else {
                self.message = "Invalid points amount. Must be at least 10 points."
            }
            self.showRedeemError = true
            return
        }
        
        // Clear previous state
        self.message = ""
        self.lastRedeemResponse = nil
        
        service.redeemPoints(userId: userId, points: points)
    }
    
    /// Reset error state
    func clearError() {
        message = ""
        showRedeemError = false
    }
    
    /// Reset success state
    func clearSuccess() {
        showRedeemSuccess = false
    }
    
    /// Fetch user's available vouchers
    func fetchVouchers(userId: Int) {
        guard userId > 0 else {
            return
        }
        isLoadingVouchers = true
        service.fetchVouchers(userId: userId)
    }
}

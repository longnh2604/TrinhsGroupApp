import Foundation
import Combine

final class PointsViewModel: ObservableObject {
    @Published var balance: Double?
    @Published var isLoading: Bool = false
    @Published var message: String = ""

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
                self?.message = err
            }
            .store(in: &cancellableSet)

        service.pointsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] points in
                self?.balance = points?.balance
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
}

//
//  AuthServices.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation
import Combine
import SwiftyJSON

protocol BaseServiceProtocol {
    var loadingPublisher: AnyPublisher<Bool, Never> { get }
    var errorPublisher: AnyPublisher<String, Never> { get }
}

protocol AuthServicesProtocol: BaseServiceProtocol {
    var authenticatePublisher: AnyPublisher<UserAuth?, Never> { get }
    var userPublisher: AnyPublisher<User, Never> { get }
    var loginPublisher: AnyPublisher<Bool, Never> { get }
    var forgotPublisher: AnyPublisher<Bool, Never> { get }
    var updatedUserPublisher: AnyPublisher<Bool, Never> { get }
}

class AuthServices: AuthServicesProtocol {
    public private(set) lazy var authenticatePublisher: AnyPublisher<UserAuth?, Never> = $authUser.eraseToAnyPublisher()
    public private(set) lazy var userPublisher: AnyPublisher<User, Never> = $user.eraseToAnyPublisher()
    public private(set) lazy var loginPublisher: AnyPublisher<Bool, Never> = $isLoggedIn.eraseToAnyPublisher()
    public private(set) lazy var createdUserPublisher: AnyPublisher<Bool, Never> = $isCreated.eraseToAnyPublisher()
    public private(set) lazy var updatedUserPublisher: AnyPublisher<Bool, Never> = $isUpdated.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var forgotPublisher: AnyPublisher<Bool, Never> = $isReset.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    private var cancellableSet: Set<AnyCancellable> = []
    @Published private var isLoading: Bool = false
    @Published private var isLoggedIn: Bool = false
    @Published private var isUpdated: Bool = false
    @Published private var isCreated: Bool = false
    @Published private var isReset: Bool = false
    @Published private var error: String = ""
    @Published var user : User = .empty
    @Published var authUser : UserAuth?
    
    private let api = WooCommerceAPI()

    private struct AvatarResponse: Decodable {
        let avatarURL: String

        enum CodingKeys: String, CodingKey {
            case avatarURL = "avatar_url"
        }
    }
    
    func createUser(username: String, firstName: String, lastName: String, password: String, email: String) {
        self.isLoading.toggle()
        let params = [
            "email": "\(email)",
            "first_name": "\(firstName)",
            "last_name": "\(lastName)",
            "username": "\(username)",
            "password": "\(password)",
        ] as [String : String]
        
        api.request(endpoint: .createCustomer, method: .POST, params: params) { (result: Result<User, Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print(data)
                    self.isCreated = true
                case .failure(let error):
                    if let wooError = error as? WooErrorResponse {
                        print("WooCommerce error: \(wooError.message)")
                        self.error = wooError.message
                    } else {
                        print("Unexpected error: \(error.localizedDescription)")
                        self.error = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func onAuthUser(email: String, password: String) {
        self.isLoading.toggle()
        api.requestBasicAuth(endpoint: .authenticate, method: .POST, email: email, password: password) { (result: Result<UserAuth, Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let userAuth):
                    print("Authentication successful! Token: \(userAuth.token)")
                    print("User Email: \(userAuth.email)")
                    print("Username: \(userAuth.username)")
                    print("Display Name: \(userAuth.displayName)")
                    self.authUser = userAuth
                    self.isLoggedIn = true
                case .failure(let error):
                    print("Authentication failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func onForgotPassword(email: String) {
        self.isLoading.toggle()
        api.sendPasswordReset(endpoint: .forgotPassword, email: email) { (result: Result<Bool, any Error>) in
            self.isLoading.toggle()
            switch result {
            case .success(_):
                print("Password reset email sent")
                self.isReset = true
            case .failure(let error):
                print("Password reset failed: \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
        }
    }
    

    func updateUser(user: User, password: String) {
        guard user.id > 0 else {
            error = "Invalid user account"
            return
        }

        isLoading = true
        var body: [String: Any] = [
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "billing": [
                "first_name": user.billing.first_name,
                "last_name": user.billing.last_name,
                "company": user.billing.company ?? "",
                "country": user.billing.country,
                "address_1": user.billing.address_1,
                "city": user.billing.city,
                "postcode": user.billing.postcode,
                "state": user.billing.state,
                "email": user.billing.email,
                "phone": user.billing.phone
            ],
            "shipping": [
                "first_name": user.shipping.first_name,
                "last_name": user.shipping.last_name,
                "company": user.shipping.company ?? "",
                "country": user.shipping.country,
                "address_1": user.shipping.address_1,
                "city": user.shipping.city,
                "postcode": user.shipping.postcode,
                "state": user.shipping.state,
                "phone": user.shipping.phone ?? ""
            ]
        ]
        if !password.isEmpty {
            body["password"] = password
        }

        api.request(endpoint: .specificCustomer(customerID: user.id), method: .PUT, body: body) { [weak self] (result: Result<User, Error>) in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let updatedUser):
                    self.user = updatedUser
                    self.isUpdated = true
                case .failure(let error):
                    self.error = (error as? WooErrorResponse)?.message ?? error.localizedDescription
                }
            }
        }
    }
    
    func fetchingUserInfo(email: String) {
        self.isLoading.toggle()
        let params = ["email" : email]
        api.request(endpoint: .getUserInfo, method: .GET, params: params) { (result: Result<[User], Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    guard let user = data.first else { return }
                    print(user)
                    self.user = user
                case .failure(let error):
                    print("Authentication failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func updateAvatar(
        userId: Int,
        imageData: Data,
        mimeType: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        DispatchQueue.main.async { self.isLoading = true }

        api.uploadCustomerAvatar(
            customerID: userId,
            imageData: imageData,
            fileName: "avatar.jpg",
            mimeType: mimeType
        ) { [weak self] (result: Result<AvatarResponse, Error>) in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let response):
                    completion(.success(response.avatarURL))
                case .failure(let error):
                    self.error = (error as? WooErrorResponse)?.message ?? error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    /// Permanently delete the customer account (WooCommerce requires force=true).
    func deleteAccount(
        userId: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.main.async { self.isLoading = true }

        api.request(endpoint: .specificCustomer(customerID: userId), method: .DELETE, params: ["force": "true"]) { [weak self] (result: Result<User, Error>) in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    self.error = (error as? WooErrorResponse)?.message ?? error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    func removeAvatar(
        userId: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.main.async { self.isLoading = true }

        api.request(endpoint: .customerAvatar(customerID: userId), method: .DELETE) { [weak self] (result: Result<AvatarResponse, Error>) in
            guard let self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = (error as? WooErrorResponse)?.message ?? error.localizedDescription
                    completion(.failure(error))
                }
            case .success:
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(.success(()))
                }
            }
        }
    }
}

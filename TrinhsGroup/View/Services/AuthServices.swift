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

    private struct RegistrationResponse: Decodable {
        let success: Bool
        let id: Int
        let email: String
    }

    /// Signup goes through the server-side `trinh-app/v1/register` route, which creates the
    /// customer with WordPress's own APIs. That is why the app can ship a read-only
    /// consumer key — account creation is the only write that predates having a JWT.
    func createUser(username: String, firstName: String, lastName: String, password: String, email: String) {
        self.isLoading.toggle()
        let body: [String: Any] = [
            "email": email,
            "username": username,
            "password": password,
            "name": [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        ]

        api.request(endpoint: .register, method: .POST, body: body) { (result: Result<RegistrationResponse, Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print("Registered customer \(data.id) <\(data.email)>")
                    self.isCreated = true
                case .failure(let error):
                    if let wooError = error as? WooErrorResponse {
                        print("Registration error: \(wooError.message)")
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

        api.request(endpoint: .me, method: .PUT, body: body) { [weak self] (result: Result<User, Error>) in
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
    
    /// Loads the signed-in customer. The account is identified by the JWT, so no email
    /// lookup is sent — the previous `?email=` query could read any customer in the store.
    func fetchingUserInfo() {
        self.isLoading.toggle()
        api.request(endpoint: .me, method: .GET) { (result: Result<User, Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let user):
                    print(user)
                    self.user = user
                case .failure(let error):
                    print("Fetching user failed: \(error.localizedDescription)")
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

    /// Permanently delete the signed-in customer's own account. The server resolves which
    /// account from the JWT and passes force=true to WooCommerce itself.
    func deleteAccount(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.main.async { self.isLoading = true }

        api.request(endpoint: .me, method: .DELETE) { [weak self] (result: Result<User, Error>) in
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

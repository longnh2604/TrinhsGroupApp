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
        self.isLoading.toggle()
        APIClient.shared.onUpdateUser(user: user, password: password) { success, data, error in
            if success {
                if data != nil {
                    self.isUpdated = true
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
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
}

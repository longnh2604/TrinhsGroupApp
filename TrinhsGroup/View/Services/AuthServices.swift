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
    @Published var user : User = User.default
    @Published var authUser : UserAuth?
    
    func createUser(username: String, password: String, email: String) {
        self.isLoading.toggle()
        let api = WooCommerceOAuth()
        
        api.request(endpoint: .createCustomer, method: .POST) { (result: Result<User, Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print(data)
                    self.isCreated = true
                case .failure(let error):
                    print("Authentication failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func onAuthUser(email: String, password: String) {
        self.isLoading.toggle()
        let api = WooCommerceOAuth()
        
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
        let api = WooCommerceOAuth()
        
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
        APIClient.shared.onFetchUserInfo(email: email) { success, data, error in
            if success {
                if let data = data?.first {
                    self.user = data
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        }
    }
}

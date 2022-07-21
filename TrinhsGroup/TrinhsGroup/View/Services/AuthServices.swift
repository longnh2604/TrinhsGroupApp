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
    var userPublisher: AnyPublisher<User, Never> { get }
    var loginPublisher: AnyPublisher<Bool, Never> { get }
    var updatedUserPublisher: AnyPublisher<Bool, Never> { get }
}

class AuthServices: AuthServicesProtocol {
    public private(set) lazy var userPublisher: AnyPublisher<User, Never> = $user.eraseToAnyPublisher()
    public private(set) lazy var loginPublisher: AnyPublisher<Bool, Never> = $isLoggedIn.eraseToAnyPublisher()
    public private(set) lazy var updatedUserPublisher: AnyPublisher<Bool, Never> = $isUpdated.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    private var cancellableSet: Set<AnyCancellable> = []
    @Published private var isLoading: Bool = false
    @Published private var isLoggedIn: Bool = false
    @Published private var isUpdated: Bool = false
    @Published private var error: String = ""
    @Published var user : User = User.default
    
    func createUser(username: String, password: String, email: String) {
        self.isLoading.toggle()
        APIClient.shared.onCreateUser(username: username, password: password, email: email) { success, data, error in
            if success {
                if let data = data {
                    self.user.id = data["id"].intValue
                    self.user.email = data["email"].stringValue
                    self.user.username = data["username"].stringValue
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        }
    }
    
    func onAuthUser(email: String, password: String) {
        self.isLoading.toggle()
        APIClient.shared.onAuthUser(email: email, password: password) { success, data, error in
            if success {
                if let data = data {
                    self.user.id = data["id"].intValue
                    self.user.email = data["user_email"].stringValue
                    self.user.username = data["user_display_name"].stringValue
                    self.isLoggedIn = true
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
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
    
    func fetchingUserInfo(id: Int) {
        self.isLoading.toggle()
        APIClient.shared.onFetchUserInfo(id: id) { success, data, error in
            if success {
                if let data = data {
                    self.user = data
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        }
    }
}

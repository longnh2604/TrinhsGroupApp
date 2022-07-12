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
}

class AuthServices: AuthServicesProtocol {
    public private(set) lazy var userPublisher: AnyPublisher<User, Never> = $user.eraseToAnyPublisher()
    public private(set) lazy var loginPublisher: AnyPublisher<Bool, Never> = $isLoggedIn.eraseToAnyPublisher()
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
                    self.user.password = password
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
                    self.user.password = password
                    self.isLoggedIn = true
                }
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        }
    }
    
//    func getUser() {
//        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/customers/\(id)?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
//            print("Invalid URL")
//            return
//        }
//        let request = URLRequest(url: url)
//
//        URLSession.shared.dataTask(with: request) {data, response, error in
//            if let data = data {
//                if let decodedResponse = try? JSONDecoder().decode(User.self, from: data) {
//                    DispatchQueue.main.async {
//                        self.user = decodedResponse
//                    }
//                    return
//                }
//            }
//            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
//        }.resume()
//    }

    func updateUser(user: User) {
        self.isLoading.toggle()
        APIClient.shared.onUpdateUser(user: user) { success, data, error in
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
}

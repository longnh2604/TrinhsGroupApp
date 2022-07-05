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
    
    
//
//    func updateUser() {
//        self.showLoading.toggle()
//        // prepare json data
//        let json: [String: Any] = [
//            "email": user.email,
//            "password": password,
//            "billing": [
//                "first_name":user.billing.first_name,
//                "last_name":user.billing.last_name,
//                "company":user.billing.company,
//                "country":user.billing.country,
//                "address_1":user.billing.address_1,
//                "address_2":user.billing.address_2,
//                "city":user.billing.city,
//                "postcode":user.billing.postcode,
//                "state":user.billing.state,
//                "email":user.billing.email,
//                "phone":user.billing.phone
//            ],
//            "shipping": [
//                "first_name":user.shipping.first_name,
//                "last_name":user.shipping.last_name,
//                "company":user.shipping.company,
//                "country":user.shipping.country,
//                "address_1":user.shipping.address_1,
//                "address_2":user.shipping.address_2,
//                "city":user.shipping.city,
//                "postcode":user.shipping.postcode,
//                "state":user.shipping.state
//            ]
//        ]
//
//        let jsonData = try? JSONSerialization.data(withJSONObject: json)
//
//        // Prepare URL"
//        let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/customers/\(id)?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)")
//        guard let requestUrl = url else { fatalError() }
//        // Prepare URL Request Object
//        var request = URLRequest(url: requestUrl)
//        request.httpMethod = "PUT"
//
//        //HTTP Headers
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("application/json", forHTTPHeaderField: "Accept")
//
//        // Set HTTP Request Body
//        request.httpBody = jsonData//postString.data(using: String.Encoding.utf8);
//        // Perform HTTP Request
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            self.showLoading.toggle()
//            // Check for Error
//            if let error = error {
//                print("Error took place \(error)")
//                return
//            }
//            let json = JSON(data!)
//            print(json)
//        }
//        task.resume()
//    }

}

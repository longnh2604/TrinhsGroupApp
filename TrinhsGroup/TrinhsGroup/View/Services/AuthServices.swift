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
    
}

class AuthServices: AuthServicesProtocol {
    
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    private var cancellableSet: Set<AnyCancellable> = []
    @Published private var isLoading: Bool = false
    @Published private var error: String = ""
    
    func createUser(username: String, password: String, email: String) {
        self.isLoading.toggle()
        APIClient.shared.onCreateUser(username: username, password: password, email: email) { success, error in
            if success {
//                self.password = ""
//                self.id = json["id"].intValue
//                self.userEmail = json["email"].stringValue
//                self.displayName = json["username"].stringValue
            } else {
                self.error = error ?? ""
            }
            self.isLoading.toggle()
        }
    }
    
//    func authUser() {
//        self.showLoading.toggle()
//        // Prepare URL"
//        let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/woo-tools-app/user/login")
//        guard let requestUrl = url else { fatalError() }
//        // Prepare URL Request Object
//        var request = URLRequest(url: requestUrl)
//        request.httpMethod = "POST"
//        request.setValue(SECURITY_CODE, forHTTPHeaderField:"Security")
//
//        // HTTP Request Parameters which will be sent in HTTP Request Body
//        let postString = "username=\(email)&password=\(password)";
//        // Set HTTP Request Body
//        request.httpBody = postString.data(using: String.Encoding.utf8);
//        // Perform HTTP Request
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//
//            self.showLoading.toggle()
//            // Check for Error
//            if let error = error {
//                print("Error took place \(error)")
//                return
//            }
//            let json = JSON(data!)
//            print(json)
//
//            DispatchQueue.main.async {
//                if json["message"].exists() {
//                    self.message = json["message"].stringValue.html2AttributedString ?? ""
//                    self.showDialog = true
//                }else{
//                    self.password = ""
//                    self.id = json["ID"].intValue
//                    self.userEmail = json["data"]["user_email"].stringValue
//                    self.displayName = json["data"]["display_name"].stringValue
//                    self.isLogin = true
//                }
//            }
//
//        }
//        task.resume()
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
//
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
}

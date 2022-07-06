//
//  AuthViewModel.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI
import SwiftyJSON
import Combine

class AuthViewModel: ObservableObject {
    
    @AppStorage("isLogin") var isLogin : Bool = false
    @Published var user : User = User.default
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var showLoading = false
    @Published var message: String = ""
    @Published var showEditProfile = false
    @Published var showEditAddress = false
    
    private var service: AuthServices = AuthServices()
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(service: AuthServices = AuthServices()) {
        self.service = service
        self.bindingData()
    }
    
    func bindingData() {
        service.loadingPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .assign(to: &$showLoading)
        
        service.errorPublisher
            .receive(on: RunLoop.main)
            .sink { error in
                self.message = error
            }
            .store(in: &cancellableSet)
        
        service.userPublisher
            .receive(on: RunLoop.main)
            .assign(to: &$user)
        
        service.loginPublisher
            .receive(on: RunLoop.main)
            .sink { isLogined in
                self.isLogin = isLogined
            }
            .store(in: &cancellableSet)
    }
    
    public func createUser() {
        if username.isEmpty || email.isEmpty || password.isEmpty {
            message = "Please fill all data"
            return
        }
        service.createUser(username: username, password: password, email: email)
    }
    
    public func onAuthUser() {
        email = "all4onegiallorossi@gmail.com"
        password = "Batigol@123"
        
        if email.isEmpty || password.isEmpty {
            message = "Please fill all data"
            return
        }
        service.onAuthUser(email: email, password: password)
    }
    
    public func updateUser() {
        self.showLoading.toggle()
        // prepare json data
        let json: [String: Any] = [
            "email": user.email,
            "password": password,
            "billing": [
                "first_name":user.billing.first_name,
                "last_name":user.billing.last_name,
                "company":user.billing.company,
                "country":user.billing.country,
                "address_1":user.billing.address_1,
                "address_2":user.billing.address_2,
                "city":user.billing.city,
                "postcode":user.billing.postcode,
                "state":user.billing.state,
                "email":user.billing.email,
                "phone":user.billing.phone
            ],
            "shipping": [
                "first_name":user.shipping.first_name,
                "last_name":user.shipping.last_name,
                "company":user.shipping.company,
                "country":user.shipping.country,
                "address_1":user.shipping.address_1,
                "address_2":user.shipping.address_2,
                "city":user.shipping.city,
                "postcode":user.shipping.postcode,
                "state":user.shipping.state
            ]
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        // Prepare URL"
        let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/customers/\(user.id)?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)")
        guard let requestUrl = url else { fatalError() }
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "PUT"
        
        //HTTP Headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set HTTP Request Body
        request.httpBody = jsonData//postString.data(using: String.Encoding.utf8);
        // Perform HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            self.showLoading.toggle()
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                return
            }
            let json = JSON(data!)
            print(json)
        }
        task.resume()
    }
    
}

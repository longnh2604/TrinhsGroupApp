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
    @AppStorage("id") var id : Int = -1
    @AppStorage("userEmail") var userEmail : String = ""
    @AppStorage("displayName") var displayName : String = ""
    @Published var user : User = User.default
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var showError: Bool = false
    @Published var showLoading = false
    @Published var message: String = ""
    
    private var service: AuthServices = AuthServices()
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(service: AuthServices = AuthServices()) {
        self.service = service
        self.bindingData()
    }
    
    func bindingData() {
        self.service.loadingPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .assign(to: &$showLoading)
        
        self.service.errorPublisher
            .receive(on: RunLoop.main)
            .sink { error in
                self.message = error
                self.showError = true
            }
            .store(in: &cancellableSet)
    }
    
    public func createUser() {
        if username.isEmpty || email.isEmpty || password.isEmpty {
            message = "Please fill all data"
            showError = true
            return
        }
        service.createUser(username: username, password: password, email: email)
    }
    
}

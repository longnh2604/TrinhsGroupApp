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
    
    public func onUpdateUser(user: User) {
        service.updateUser(user: user)
    }
}

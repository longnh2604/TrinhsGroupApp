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
    @Published var user : User = .empty
    @Published var authUser: UserAuth?
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var showLoading = false
    @Published var message: String = ""
    @Published var showEditProfile = false
    @Published var showEditAddress = false
    @Published var isUpdatedUser = false
    @Published var isCreatedUser = false
    @Published var isShowForgot = false
    
    private var service: AuthServices = AuthServices()
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(service: AuthServices = AuthServices()) {
        self.service = service
        self.bindingData()
    }
    
    func bindingData() {
        service.loadingPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.showLoading = isLoading
            }
            .store(in: &cancellableSet)
        
        service.errorPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] error in
                self?.message = error
            }
            .store(in: &cancellableSet)
        
        service.userPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.user = user
            }
            .store(in: &cancellableSet)
        
        service.loginPublisher
            .receive(on: RunLoop.main)
            .sink { isLogined in
                self.isLogin = isLogined
            }
            .store(in: &cancellableSet)
        
        service.createdUserPublisher
            .receive(on: RunLoop.main)
            .sink { isCreated in
                self.isCreatedUser = isCreated
            }
            .store(in: &cancellableSet)
        
        service.updatedUserPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { isUpdated in
                self.isUpdatedUser = isUpdated
                if isUpdated {
                    DispatchQueue.main.asyncAfter(deadline: .now() + ALERT_MESSAGE_DURATION) {
                        self.isUpdatedUser = false
                    }
                }
            }
            .store(in: &cancellableSet)
        
        service.forgotPublisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { isReset in
                self.isShowForgot = !isReset
            }
            .store(in: &cancellableSet)
        
        service.authenticatePublisher
            .receive(on: RunLoop.main)
            .sink { authUser in
                self.authUser = authUser
            }
            .store(in: &cancellableSet)
    }
    
    public func createUser() {
        if username.isEmpty || email.isEmpty || password.isEmpty {
            message = "Please fill all data"
            return
        }
        service.createUser(username: username, firstName: "", lastName: "", password: password, email: email)
    }
    
    public func onAuthUser() {
        email = "Test02@abc.com"
        password = "abc123"

        if email.isEmpty || password.isEmpty {
            message = "Please fill all data"
            return
        }
        service.onAuthUser(email: email, password: password)
    }
    
    public func onUpdateUser(user: User) {
        service.updateUser(user: user, password: password)
    }
    
    public func checkUserUpdatedBillInfo() -> Bool {
//        if !user.billing.checkFilledData() {
//            message = "Please fill your billing info before start to create order, thank you."
//            return false
//        }
        return true
    }
    
    public func onGetUser() {
        guard let user = authUser else { return }
        service.fetchingUserInfo(email: user.email)
    }
    
    public func onForgotPassword(email: String) {
        service.onForgotPassword(email: email)
    }
}

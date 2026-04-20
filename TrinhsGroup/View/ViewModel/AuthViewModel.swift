//
//  AuthViewModel.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import SwiftUI
import SwiftyJSON
import Combine
import UIKit

class AuthViewModel: ObservableObject {
    
    @AppStorage("isLogin") var isLogin : Bool = false
    @AppStorage("authJWTToken") private var persistedJWTToken: String = ""
    @AppStorage("authUserEmail") private var persistedAuthEmail: String = ""
    @AppStorage("authUsername") private var persistedAuthUsername: String = ""
    @AppStorage("authDisplayName") private var persistedAuthDisplayName: String = ""
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
        restorePersistedAuthSession()
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
            .dropFirst()
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
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { authUser in
                self.authUser = authUser
                if let authUser {
                    self.persistedJWTToken = authUser.token
                    self.persistedAuthEmail = authUser.email
                    self.persistedAuthUsername = authUser.username
                    self.persistedAuthDisplayName = authUser.displayName
                }
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
        restorePersistedAuthSession()

        let emailToFetch = authUser?.email.nonEmptyValue
            ?? user.email.nonEmptyValue
            ?? persistedAuthEmail.nonEmptyValue

        guard let emailToFetch else { return }
        service.fetchingUserInfo(email: emailToFetch)
    }
    
    public func onForgotPassword(email: String) {
        service.onForgotPassword(email: email)
    }

    public func onUpdateAvatar(
        image: UIImage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        restorePersistedAuthSession()

        guard let token = resolvedJWTToken() else {
            let error = NSError(
                domain: "AuthViewModel",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để cập nhật avatar."]
            )
            message = error.localizedDescription
            completion(.failure(error))
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            let error = NSError(
                domain: "AuthViewModel",
                code: 422,
                userInfo: [NSLocalizedDescriptionKey: "Không thể xử lý ảnh đã chọn."]
            )
            message = error.localizedDescription
            completion(.failure(error))
            return
        }

        let fileName = "avatar-\(user.id)-\(Int(Date().timeIntervalSince1970)).jpg"
        service.updateAvatar(jwtToken: token, imageData: imageData, fileName: fileName, mimeType: "image/jpeg") { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let avatarURL):
                    if !avatarURL.isEmpty {
                        self.user.avatar_url = avatarURL
                    }
                    completion(.success(()))
                case .failure(let error):
                    self.message = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    public func onRemoveAvatar(
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        restorePersistedAuthSession()

        guard let token = resolvedJWTToken() else {
            let error = NSError(
                domain: "AuthViewModel",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại để xóa avatar."]
            )
            message = error.localizedDescription
            completion(.failure(error))
            return
        }

        service.removeAvatar(jwtToken: token) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.user.avatar_url = nil
                    completion(.success(()))
                case .failure(let error):
                    self.message = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    public func logout() {
        authUser = nil
        user = .empty
        isLogin = false
        persistedJWTToken = ""
        persistedAuthEmail = ""
        persistedAuthUsername = ""
        persistedAuthDisplayName = ""
        password = ""
    }

    private func restorePersistedAuthSession() {
        guard authUser == nil else { return }
        guard let token = persistedJWTToken.nonEmptyValue,
              let email = persistedAuthEmail.nonEmptyValue else {
            return
        }

        authUser = UserAuth(
            token: token,
            email: email,
            username: persistedAuthUsername,
            displayName: persistedAuthDisplayName
        )
    }

    private func resolvedJWTToken() -> String? {
        if let token = authUser?.token.nonEmptyValue {
            return token
        }
        if let token = persistedJWTToken.nonEmptyValue {
            return token
        }
        return nil
    }
}

private extension String {
    var nonEmptyValue: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}

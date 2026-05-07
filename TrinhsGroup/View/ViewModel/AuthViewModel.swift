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
    @AppStorage("tokenExpirationDate") private var tokenExpirationTimestamp: Double = 0
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
    @Published var isTokenExpired = false
    
    private var service: AuthServices = AuthServices()
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(service: AuthServices = AuthServices()) {
        self.service = service
        validateAndRestoreSession()
        self.bindingData()
    }
    
    // MARK: - Token Validation
    
    /// Validate token expiration and restore session if valid
    private func validateAndRestoreSession() {
        // Check if we have stored credentials
        guard persistedJWTToken.nonEmptyValue != nil,
              persistedAuthEmail.nonEmptyValue != nil else {
            // No stored session, user needs to login
            print("🔐 No stored session found")
            isLogin = false
            return
        }
        
        // Check if token is expired
        if isTokenExpiredCheck() {
            print("🔐 Token expired, clearing session")
            clearExpiredSession()
            isTokenExpired = true
            return
        }
        
        // Token is still valid, restore session
        print("🔐 Token valid, restoring session")
        restorePersistedAuthSession()
    }
    
    /// Check if the stored token has expired
    private func isTokenExpiredCheck() -> Bool {
        // First try to decode expiration from JWT token
        if let expDate = decodeJWTExpiration(token: persistedJWTToken) {
            let isExpired = expDate < Date()
            print("🔐 JWT expiration date: \(expDate), isExpired: \(isExpired)")
            return isExpired
        }
        
        // Fallback to stored expiration timestamp
        if tokenExpirationTimestamp > 0 {
            let expDate = Date(timeIntervalSince1970: tokenExpirationTimestamp)
            let isExpired = expDate < Date()
            print("🔐 Stored expiration date: \(expDate), isExpired: \(isExpired)")
            return isExpired
        }
        
        // If we can't determine expiration, assume token is valid
        print("🔐 No expiration info found, assuming token is valid")
        return false
    }
    
    /// Decode JWT token to extract expiration date
    private func decodeJWTExpiration(token: String) -> Date? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            print("🔐 Invalid JWT format")
            return nil
        }
        
        // JWT payload is the second segment (Base64 encoded)
        var base64String = segments[1]
        
        // Add padding if needed (Base64 requires length to be multiple of 4)
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String += String(repeating: "=", count: 4 - remainder)
        }
        
        // Replace URL-safe characters
        base64String = base64String
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        guard let payloadData = Data(base64Encoded: base64String) else {
            print("🔐 Failed to decode JWT Base64")
            return nil
        }
        
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            print("🔐 Failed to parse JWT payload JSON")
            return nil
        }
        
        // JWT standard uses "exp" claim for expiration (Unix timestamp)
        if let exp = payload["exp"] as? Double {
            let expirationDate = Date(timeIntervalSince1970: exp)
            print("🔐 Decoded JWT expiration: \(expirationDate)")
            return expirationDate
        }
        
        print("🔐 No 'exp' claim found in JWT")
        return nil
    }
    
    /// Clear expired session data
    private func clearExpiredSession() {
        authUser = nil
        user = .empty
        isLogin = false
        persistedJWTToken = ""
        persistedAuthEmail = ""
        persistedAuthUsername = ""
        persistedAuthDisplayName = ""
        tokenExpirationTimestamp = 0
    }
    
    /// Called to dismiss token expired message
    public func dismissTokenExpiredMessage() {
        isTokenExpired = false
    }
    
    /// Save token expiration timestamp when login
    private func saveTokenExpiration(token: String) {
        if let expDate = decodeJWTExpiration(token: token) {
            tokenExpirationTimestamp = expDate.timeIntervalSince1970
            print("🔐 Saved token expiration: \(expDate)")
        }
    }
    
    // MARK: - Binding Data
    
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
                    // Save token expiration when login
                    self.saveTokenExpiration(token: authUser.token)
                }
            }
            .store(in: &cancellableSet)
    }
    
    // MARK: - Public Methods
    
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
        tokenExpirationTimestamp = 0
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

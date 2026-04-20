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
    var authenticatePublisher: AnyPublisher<UserAuth?, Never> { get }
    var userPublisher: AnyPublisher<User, Never> { get }
    var loginPublisher: AnyPublisher<Bool, Never> { get }
    var forgotPublisher: AnyPublisher<Bool, Never> { get }
    var updatedUserPublisher: AnyPublisher<Bool, Never> { get }
}

class AuthServices: AuthServicesProtocol {
    public private(set) lazy var authenticatePublisher: AnyPublisher<UserAuth?, Never> = $authUser.eraseToAnyPublisher()
    public private(set) lazy var userPublisher: AnyPublisher<User, Never> = $user.eraseToAnyPublisher()
    public private(set) lazy var loginPublisher: AnyPublisher<Bool, Never> = $isLoggedIn.eraseToAnyPublisher()
    public private(set) lazy var createdUserPublisher: AnyPublisher<Bool, Never> = $isCreated.eraseToAnyPublisher()
    public private(set) lazy var updatedUserPublisher: AnyPublisher<Bool, Never> = $isUpdated.eraseToAnyPublisher()
    public private(set) lazy var loadingPublisher: AnyPublisher<Bool, Never> = $isLoading.eraseToAnyPublisher()
    public private(set) lazy var forgotPublisher: AnyPublisher<Bool, Never> = $isReset.eraseToAnyPublisher()
    public private(set) lazy var errorPublisher: AnyPublisher<String, Never> = $error.eraseToAnyPublisher()

    private var cancellableSet: Set<AnyCancellable> = []
    @Published private var isLoading: Bool = false
    @Published private var isLoggedIn: Bool = false
    @Published private var isUpdated: Bool = false
    @Published private var isCreated: Bool = false
    @Published private var isReset: Bool = false
    @Published private var error: String = ""
    @Published var user : User = .empty
    @Published var authUser : UserAuth?
    
    private let api = WooCommerceAPI()
    private let avatarAPI = WordPressAvatarAPI()
    
    func createUser(username: String, firstName: String, lastName: String, password: String, email: String) {
        self.isLoading.toggle()
        let params = [
            "email": "\(email)",
            "first_name": "\(firstName)",
            "last_name": "\(lastName)",
            "username": "\(username)",
            "password": "\(password)",
        ] as [String : String]
        
        api.request(endpoint: .createCustomer, method: .POST, params: params) { (result: Result<User, Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    print(data)
                    self.isCreated = true
                case .failure(let error):
                    if let wooError = error as? WooErrorResponse {
                        print("WooCommerce error: \(wooError.message)")
                        self.error = wooError.message
                    } else {
                        print("Unexpected error: \(error.localizedDescription)")
                        self.error = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func onAuthUser(email: String, password: String) {
        self.isLoading.toggle()
        api.requestBasicAuth(endpoint: .authenticate, method: .POST, email: email, password: password) { (result: Result<UserAuth, Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let userAuth):
                    print("Authentication successful! Token: \(userAuth.token)")
                    print("User Email: \(userAuth.email)")
                    print("Username: \(userAuth.username)")
                    print("Display Name: \(userAuth.displayName)")
                    self.authUser = userAuth
                    self.isLoggedIn = true
                case .failure(let error):
                    print("Authentication failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func onForgotPassword(email: String) {
        self.isLoading.toggle()
        api.sendPasswordReset(endpoint: .forgotPassword, email: email) { (result: Result<Bool, any Error>) in
            self.isLoading.toggle()
            switch result {
            case .success(_):
                print("Password reset email sent")
                self.isReset = true
            case .failure(let error):
                print("Password reset failed: \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
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
    
    func fetchingUserInfo(email: String) {
        self.isLoading.toggle()
        let params = ["email" : email]
        api.request(endpoint: .getUserInfo, method: .GET, params: params) { (result: Result<[User], Error>) in
            DispatchQueue.main.async {
                self.isLoading.toggle()
                switch result {
                case .success(let data):
                    guard let user = data.first else { return }
                    print(user)
                    self.user = user
                case .failure(let error):
                    print("Authentication failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
        }
    }

    func updateAvatar(
        jwtToken: String,
        imageData: Data,
        fileName: String,
        mimeType: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        DispatchQueue.main.async {
            self.isLoading = true
        }

        avatarAPI.uploadAvatarImage(jwtToken: jwtToken, imageData: imageData, fileName: fileName, mimeType: mimeType) { uploadResult in
            switch uploadResult {
            case .success(let media):
                self.avatarAPI.updateCurrentUserAvatar(jwtToken: jwtToken, mediaID: media.id) { updateResult in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        switch updateResult {
                        case .success(let avatarURL):
                            completion(.success(avatarURL ?? media.sourceURL ?? ""))
                        case .failure(let error):
                            self.error = error.localizedDescription
                            completion(.failure(error))
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    func removeAvatar(
        jwtToken: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.main.async {
            self.isLoading = true
        }

        avatarAPI.deleteCurrentUserAvatar(jwtToken: jwtToken) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    self.error = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
}

private struct WordPressMediaUploadResponse: Decodable {
    let id: Int
    let sourceURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceURL = "source_url"
    }
}

private struct WordPressAvatarUpdateResponse: Decodable {
    let avatarURL: String?
    let sourceURL: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case avatarURL = "avatar_url"
        case sourceURL = "source_url"
        case url
    }
}

private enum WordPressAvatarAPIError: LocalizedError {
    case invalidURL
    case missingResponse
    case unauthorized
    case imageDataMissing
    case unsupportedServer(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return L10n.Error.invalidAvatarURL.localized
        case .missingResponse:
            return L10n.Error.missingResponse.localized
        case .unauthorized:
            return L10n.Error.avatarUnauthorized.localized
        case .imageDataMissing:
            return L10n.Error.imageDataMissing.localized
        case .unsupportedServer(let message):
            return message
        }
    }
}

private final class WordPressAvatarAPI {
    private let baseURL = WOOCOMMERCE_URL
    private let session = URLSession.shared

    private enum Endpoint {
        static let media = "/wp-json/wp/v2/media"
        static let customAvatar = "/wp-json/woo-tools-app/v1/avatar"
        static let currentUser = "/wp-json/wp/v2/users/me"
        static let avatarMetaKey = "avatar_attachment_id"
    }

    func uploadAvatarImage(
        jwtToken: String,
        imageData: Data,
        fileName: String,
        mimeType: String,
        completion: @escaping (Result<WordPressMediaUploadResponse, Error>) -> Void
    ) {
        guard !jwtToken.isEmpty else {
            completion(.failure(WordPressAvatarAPIError.unauthorized))
            return
        }
        guard !imageData.isEmpty else {
            completion(.failure(WordPressAvatarAPIError.imageDataMissing))
            return
        }
        guard let url = URL(string: "\(baseURL)\(Endpoint.media)") else {
            completion(.failure(WordPressAvatarAPIError.invalidURL))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 60
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = makeMultipartBody(
            boundary: boundary,
            fieldName: "file",
            fileName: fileName,
            mimeType: mimeType,
            fileData: imageData
        )

        perform(request: request) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(WordPressMediaUploadResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateCurrentUserAvatar(
        jwtToken: String,
        mediaID: Int,
        completion: @escaping (Result<String?, Error>) -> Void
    ) {
        let customBody: [String: Any] = ["media_id": mediaID]
        requestJSON(
            path: Endpoint.customAvatar,
            method: .POST,
            jwtToken: jwtToken,
            body: customBody
        ) { result in
            switch result {
            case .success(let data):
                completion(.success(Self.extractAvatarURL(from: data)))
            case .failure(let error):
                if Self.shouldFallbackToCoreUserMeta(error) {
                    let coreBody: [String: Any] = [
                        "meta": [
                            Endpoint.avatarMetaKey: mediaID
                        ]
                    ]
                    self.requestJSON(path: Endpoint.currentUser, method: .POST, jwtToken: jwtToken, body: coreBody) { fallback in
                        switch fallback {
                        case .success(let data):
                            completion(.success(Self.extractAvatarURL(from: data)))
                        case .failure(let fallbackError):
                            if (fallbackError as NSError).code == 401 || (fallbackError as NSError).code == 403 {
                                completion(.failure(fallbackError))
                            } else {
                                completion(.failure(WordPressAvatarAPIError.unsupportedServer(L10n.Error.unsupportedAvatarUpdate.localized)))
                            }
                        }
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    func deleteCurrentUserAvatar(
        jwtToken: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        requestJSON(path: Endpoint.customAvatar, method: .DELETE, jwtToken: jwtToken, body: nil) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                if Self.shouldFallbackToCoreUserMeta(error) {
                    let coreBody: [String: Any] = [
                        "meta": [
                            Endpoint.avatarMetaKey: NSNull()
                        ]
                    ]
                    self.requestJSON(path: Endpoint.currentUser, method: .POST, jwtToken: jwtToken, body: coreBody) { fallback in
                        switch fallback {
                        case .success:
                            completion(.success(()))
                        case .failure(let fallbackError):
                            if (fallbackError as NSError).code == 401 || (fallbackError as NSError).code == 403 {
                                completion(.failure(fallbackError))
                            } else {
                                completion(.failure(WordPressAvatarAPIError.unsupportedServer(L10n.Error.unsupportedAvatarDelete.localized)))
                            }
                        }
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    private func requestJSON(
        path: String,
        method: HTTPMethod,
        jwtToken: String,
        body: [String: Any]?,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard !jwtToken.isEmpty else {
            completion(.failure(WordPressAvatarAPIError.unauthorized))
            return
        }
        guard let url = URL(string: "\(baseURL)\(path)") else {
            completion(.failure(WordPressAvatarAPIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 60
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        perform(request: request, completion: completion)
    }

    private func perform(
        request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        print("🌐 Avatar Request URL: \(request.url?.absoluteString ?? "Invalid URL")")
        print("📤 Avatar Request Method: \(request.httpMethod ?? "-")")

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(WordPressAvatarAPIError.missingResponse))
                return
            }

            let responseData = data ?? Data()
            print("📥 Avatar Response Status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    completion(.failure(WordPressAvatarAPIError.unauthorized))
                    return
                }

                if let wpError = try? JSONDecoder().decode(WooErrorResponse.self, from: responseData) {
                    completion(.failure(wpError))
                    return
                }

                let message = String(data: responseData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let fallbackMessage = message?.isEmpty == false ? message! : String(format: L10n.Error.fallbackAvatarEndpoint.localized, String(httpResponse.statusCode))
                completion(.failure(NSError(
                    domain: "WordPressAvatarAPI",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: fallbackMessage]
                )))
                return
            }

            completion(.success(responseData))
        }.resume()
    }

    private func makeMultipartBody(
        boundary: String,
        fieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private static func extractAvatarURL(from data: Data) -> String? {
        if let decoded = try? JSONDecoder().decode(WordPressAvatarUpdateResponse.self, from: data) {
            return decoded.avatarURL ?? decoded.sourceURL ?? decoded.url
        }

        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        if let avatarURL = object["avatar_url"] as? String, !avatarURL.isEmpty {
            return avatarURL
        }
        if let url = object["url"] as? String, !url.isEmpty {
            return url
        }
        if let sourceURL = object["source_url"] as? String, !sourceURL.isEmpty {
            return sourceURL
        }
        return nil
    }

    private static func shouldFallbackToCoreUserMeta(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.code == 404 || nsError.code == 405
    }
}

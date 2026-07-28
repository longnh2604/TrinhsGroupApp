//
//  WooCommerceOAuth.swift
//  TrinhsGroup
//
//  Created by ntq on 27/3/25.
//

import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

let commonURL = "/wp-json/wc/v3"

let appAPIURL = "/wp-json/trinh-app/v1"

enum WooCommerceEndpoint {

    // MARK: Unauthenticated

    case authenticate
    case forgotPassword
    /// Server-side signup, so the app never needs a write-capable consumer key.
    case register

    // MARK: Public catalog — read-only consumer key

    case fetchCategories
    case fetchPopularProducts
    case fetchProductsCategory(categoryID: Int)

    // MARK: Signed-in user — JWT, scoped server-side to the token's own account

    /// Own customer record: GET to read, PUT to update, DELETE to close the account.
    case me
    case myOrders
    case cancelMyOrder(orderID: Int)
    case myPaymentIntent(orderID: Int)
    case myVouchers
    case paymentMethods
    /// Own myCred balance. Deliberately NOT read from the customer record: WooCommerce's
    /// customers controller only emits `meta_data` for administrators
    /// (class-wc-rest-customers-v2-controller.php:82), so it is absent now that the app
    /// authenticates as the customer rather than via an admin-owned consumer key.
    case myPoints
    case redeemPoints
    case fcmRegister
    case customerAvatar(customerID: Int)

    func urlPath() -> String {
        switch self {
        case .authenticate:
            return "/wp-json/jwt-auth/v1/token"
        case .forgotPassword:
            return "/wp-login.php?action=lostpassword"
        case .register:
            return "\(appAPIURL)/register"

        case .fetchCategories:
            return "\(commonURL)/products/categories"
        case .fetchPopularProducts:
            return "\(commonURL)/products?orderby=popularity&order=desc&per_page=10"
        case .fetchProductsCategory(let id):
            return "\(commonURL)/products?category=\(id)"

        case .me:
            return "\(appAPIURL)/me"
        case .myOrders:
            return "\(appAPIURL)/me/orders"
        case .cancelMyOrder(let orderID):
            return "\(appAPIURL)/me/orders/\(orderID)/cancel"
        case .myPaymentIntent(let orderID):
            return "\(appAPIURL)/me/orders/\(orderID)/payment-intent"
        case .myVouchers:
            return "\(appAPIURL)/me/vouchers"
        case .paymentMethods:
            return "\(appAPIURL)/payment-methods"
        case .myPoints:
            // user_id is filled in server-side by trinh-api-guard from the JWT.
            return "/wp-json/bu/v1/me/points"
        case .redeemPoints:
            return "/wp-json/bu/v1/redeem"
        case .fcmRegister:
            return "\(appAPIURL)/fcm/register"
        case .customerAvatar(let customerID):
            return "\(commonURL)/customers/\(customerID)/avatar"
        }
    }

    /// `true` when the route authorises via the signed-in user's JWT rather than the
    /// read-only consumer key. Everything touching a customer, order, voucher, payment
    /// method or device token is server-scoped to the token's own account.
    var requiresJWT: Bool {
        switch self {
        case .authenticate, .forgotPassword, .register,
             .fetchCategories, .fetchPopularProducts, .fetchProductsCategory:
            return false
        case .me, .myOrders, .cancelMyOrder, .myPaymentIntent, .myVouchers,
             .paymentMethods, .myPoints, .redeemPoints, .fcmRegister, .customerAvatar:
            return true
        }
    }
}


struct WooCommerceAPI {
    /// Read-only key, loaded from the untracked Secrets.plist. Used **only** for the
    /// public catalog reads in `WooCommerceEndpoint.requiresJWT == false`.
    private var consumerKey: String { AppSecrets.wooConsumerKey }
    private var consumerSecret: String { AppSecrets.wooConsumerSecret }
    private let storeURL = "https://trinhsgroup.com.au"


    // MARK: - Authorization

    /// Attaches the correct credential for `endpoint`, or returns an error if a
    /// JWT-backed route is called without a signed-in session.
    private func applyAuthorization(to request: inout URLRequest, for endpoint: WooCommerceEndpoint) -> Error? {
        guard endpoint.requiresJWT else {
            let loginString = "\(consumerKey):\(consumerSecret)"
            if let loginData = loginString.data(using: .utf8) {
                request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")
            }
            return nil
        }

        guard let token = AuthTokenStore.token else {
            print("🔐 Refusing \(endpoint.urlPath()) — no JWT for the current session")
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
            return NSError(
                domain: "WooCommerceAPI",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Your session has expired. Please log in again."]
            )
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return nil
    }

    /// A rejected JWT means the session is gone — tell `AuthViewModel`, which is already
    /// listening on `.sessionExpired`, so the user is bounced to login exactly once.
    private func handleAuthFailure(statusCode: Int, endpoint: WooCommerceEndpoint) -> Error? {
        guard endpoint.requiresJWT, statusCode == 401 || statusCode == 403 else { return nil }
        print("🔐 \(statusCode) on \(endpoint.urlPath()) — session no longer valid")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
        return NSError(
            domain: "WooCommerceAPI",
            code: statusCode,
            userInfo: [NSLocalizedDescriptionKey: "Your session has expired. Please log in again."]
        )
    }

    
    func request<T: Decodable>(
        endpoint: WooCommerceEndpoint,
        method: HTTPMethod,
        params: [String: String] = [:],
        body: [String: Any]? = nil,
        retriesRemaining: Int = 1,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Build URL with query parameters
        var components = URLComponents(string: "\(storeURL)\(endpoint.urlPath())")!

        // Add existing params
        var queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

        // Add cache-busting timestamp for GET requests to prevent stale data
        if method == .GET {
            queryItems.append(URLQueryItem(name: "_", value: String(Int(Date().timeIntervalSince1970 * 1000))))
        }

        if !queryItems.isEmpty {
            // Merge with existing query items if URL already has them
            if components.queryItems != nil {
                components.queryItems?.append(contentsOf: queryItems)
            } else {
                components.queryItems = queryItems
            }
        }

        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 120

        // Disable caching to always get fresh data
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        // Authorization: Bearer JWT for user-scoped routes, read-only consumer key for
        // public catalog reads.
        if let authError = applyAuthorization(to: &request, for: endpoint) {
            completion(.failure(authError))
            return
        }

        // Add no-cache headers
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        // Set body if needed
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        print("🌐 Request URL: \(request.url?.absoluteString ?? "Invalid URL")")
        print("📤 Request Method: \(method.rawValue)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Response Status Code: \(httpResponse.statusCode)")
                print("📋 Response Headers: \(httpResponse.allHeaderFields)")

                if let authError = self.handleAuthFailure(statusCode: httpResponse.statusCode, endpoint: endpoint) {
                    DispatchQueue.main.async { completion(.failure(authError)) }
                    return
                }
            }

            if let error = error {
                print("❌ Network Error: \(error.localizedDescription)")
                let nsError = error as NSError
                let isTransient = nsError.domain == NSURLErrorDomain &&
                    (nsError.code == NSURLErrorNetworkConnectionLost ||
                     nsError.code == NSURLErrorTimedOut)
                if isTransient && retriesRemaining > 0 {
                    print("🔄 Transient error (\(nsError.code)) — retrying in 1.5s, \(retriesRemaining) attempt(s) left")
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
                        self.request(
                            endpoint: endpoint,
                            method: method,
                            params: params,
                            body: body,
                            retriesRemaining: retriesRemaining - 1,
                            completion: completion
                        )
                    }
                    return
                }
                completion(.failure(error))
                return
            }

            guard let data = data else {
                print("❌ No data received")
                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
                return
            }

            // Print raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Raw JSON Response (\(data.count) bytes):")
                print(jsonString)
            } else {
                print("⚠️ Response data is not valid UTF-8 string")
            }
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                print("✅ Successfully decoded response")
                DispatchQueue.main.async {
                    completion(.success(decodedData))
                }
            } catch let decodingError {
                print("❌ Decoding Error: \(decodingError)")
                print("🔍 Error details:")
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("  Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .valueNotFound(let type, let context):
                        print("  Value not found: \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .keyNotFound(let key, let context):
                        print("  Key not found: '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .dataCorrupted(let context):
                        print("  Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                        print("  Error: \(context.debugDescription)")
                    @unknown default:
                        print("  Unknown decoding error")
                    }
                }
                
                // Try to decode the custom bu/v1 redeem error shape, then WooCommerce's.
                if let customError = try? JSONDecoder().decode(RedeemErrorResponse.self, from: data) {
                    print("📋 Custom Error Response: \(customError.error)")
                    let error = NSError(
                        domain: "RedeemError",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: customError.error]
                    )
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                } else if let wooError = try? JSONDecoder().decode(WooErrorResponse.self, from: data) {
                    print("📋 WooCommerce Error Response decoded")
                    DispatchQueue.main.async {
                        completion(.failure(wooError))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(decodingError))
                    }
                }
            }
        }.resume()
    }

    /// Upload a customer avatar directly to the WordPress Media Library.
    func uploadCustomerAvatar<T: Decodable>(
        customerID: Int,
        imageData: Data,
        fileName: String,
        mimeType: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: "\(storeURL)\(WooCommerceEndpoint.customerAvatar(customerID: customerID).urlPath())") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.timeoutInterval = 120
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let endpoint = WooCommerceEndpoint.customerAvatar(customerID: customerID)
        if let authError = applyAuthorization(to: &request, for: endpoint) {
            completion(.failure(authError))
            return
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
                return
            }
            if let response = try? JSONDecoder().decode(T.self, from: data) {
                completion(.success(response))
            } else if let error = try? JSONDecoder().decode(WooErrorResponse.self, from: data) {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "AvatarUpload", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid avatar upload response."])))
            }
        }.resume()
    }
    
    func requestBasicAuth<T: Decodable>(
        endpoint: WooCommerceEndpoint,
        method: HTTPMethod,
        email: String,
        password: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let requestURL = URL(string: "\(storeURL)\(endpoint.urlPath())")!
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        
        let postString = "username=\(email)&password=\(password)"
        request.httpBody = postString.data(using: String.Encoding.utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                print("Decoded JSON: \(jsonObject)")
                
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedData))
                }
            } catch {
                print("JSON Decoding Error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    func sendPasswordReset(
        endpoint: WooCommerceEndpoint,
        email: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        let requestURL = URL(string: "\(storeURL)\(endpoint.urlPath())")!
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        
        let postString = "user_login=\(email)"
        request.httpBody = postString.data(using: String.Encoding.utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let _ = data else {
                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }.resume()
    }
}

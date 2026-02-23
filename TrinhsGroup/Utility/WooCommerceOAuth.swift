//
//  WooCommerceOAuth.swift
//  TrinhsGroup
//
//  Created by ntq on 27/3/25.
//

import Foundation
import CommonCrypto

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

let commonURL = "/wp-json/wc/v3"

enum WooCommerceEndpoint {
    case authenticate
    case forgotPassword
    case customers
    case createCustomer
    case specificCustomer(customerID: Int)
    case products
    case specificOrder(orderID: Int)
    case specificProduct(productID: Int)
    case fetchCategories
    case getUserInfo
    case fetchPopularProducts
    case fetchProductsCategory(categoryID: Int)
    case fetchPaymentMethods
    case onCreateOrder
    case fetchHistoryOrders(customerID: Int)
    case getStripePaymentIntent(orderID: Int)

    func urlPath() -> String {
        switch self {
        case .authenticate:
            return "/wp-json/jwt-auth/v1/token"
        case .forgotPassword:
            return "/wp-login.php?action=lostpassword"
        case .createCustomer, .customers:
            return "/wp-json/wc/v3/customers"
        case .specificCustomer(let customerID):
            return "/wp-json/wc/v3/customers/\(customerID)"
        case .products:
            return "/wp-json/wc/v3/products"
        case .specificOrder(let orderID):
            return "/wp-json/wc/v3/orders/\(orderID)"
        case .specificProduct(let productID):
            return "/wp-json/wc/v3/products/\(productID)"
        case .fetchCategories:
            return "\(commonURL)/products/categories"
        case .getUserInfo:
            return "\(commonURL)/customers"
        case .fetchPopularProducts:
            return "\(commonURL)/products?orderby=popularity&order=desc&per_page=10"
        case .fetchProductsCategory(let id):
            return "\(commonURL)/products?category=\(id)"
        case .fetchPaymentMethods:
            return "\(commonURL)/payment_gateways"
        case .onCreateOrder:
            return "\(commonURL)/orders"
        case .fetchHistoryOrders(let customerID):
            return "\(commonURL)/orders?customer=\(customerID)&page=1&per_page=100"
        case .getStripePaymentIntent(let orderID):
            return "\(commonURL)/orders/\(orderID)/stripe/payment-intent"
        }
    }
}

extension String {
    func addingPercentEncodingRFC3986() -> String? {
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}

struct WooCommerceAPI {
    private let consumerKey = "ck_7a7ff2a5389700b8bff6f7c113882899a8a29f07"
    private let consumerSecret = "cs_2aed31668184fb02b3590c69eb96c4686ba7038e"
    private let storeURL = "https://trinhsgroup.au"

    /// Generate OAuth signature
    private func generateOAuthSignature(httpMethod: HTTPMethod, endpoint: WooCommerceEndpoint, params: [String: String]) -> String {
        let baseURL = "\(storeURL)\(endpoint.urlPath())"

        var oauthParams: [String: String] = [
            "oauth_consumer_key": consumerKey,
            "oauth_nonce": UUID().uuidString,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(Int(Date().timeIntervalSince1970)),
            "oauth_version": "1.0"
        ]

        // Merge request parameters into OAuth parameters
        oauthParams.merge(params) { (_, new) in new }

        // Sort parameters alphabetically by key
        let sortedParams = oauthParams.sorted { $0.key < $1.key }
        let parameterString = sortedParams.map { "\($0.key)=\($0.value.addingPercentEncodingRFC3986() ?? "")" }.joined(separator: "&")

        let signatureBase = "\(httpMethod.rawValue)&" +
                            "\(baseURL.addingPercentEncodingRFC3986() ?? "")&" +
                            "\(parameterString.addingPercentEncodingRFC3986() ?? "")"

        let signingKey = "\(consumerSecret)&"  // Token Secret not used in your case

        return hmacSHA1(data: signatureBase, key: signingKey)
    }

    /// Generate HMAC-SHA1 signature
    private func hmacSHA1(data: String, key: String) -> String {
        let keyData = key.data(using: .utf8)!
        let data = data.data(using: .utf8)!

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))

        keyData.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA1),
                    keyBytes.baseAddress, keyData.count,
                    dataBytes.baseAddress, data.count,
                    &digest
                )
            }
        }

        let dataDigest = Data(digest)
        return dataDigest.base64EncodedString()
    }

    // Old Oauth request
    /// Generic API request function
//    func request<T: Decodable>(
//        endpoint: WooCommerceEndpoint,
//        method: HTTPMethod,
//        params: [String: String] = [:],
//        body: [String: Any]? = nil,
//        completion: @escaping (Result<T, Error>) -> Void
//    ) {
//        var oauthParams = params
//        // Generate the OAuth signature
//        let oauthSignature = generateOAuthSignature(httpMethod: method, endpoint: endpoint, params: oauthParams)
//        oauthParams["oauth_signature"] = oauthSignature
//
//        let queryString = oauthParams.map { "\($0.key)=\($0.value.addingPercentEncodingRFC3986() ?? "")" }.joined(separator: "&")
//        let requestURL = URL(string: "\(storeURL)\(endpoint.urlPath())?\(queryString)")!
//
//        var request = URLRequest(url: requestURL)
//        request.httpMethod = method.rawValue
//
//        if let body = body {
//            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        }
//        print("Final Request URL: \(request.url?.absoluteString ?? "Invalid URL")")
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
//                return
//            }
//
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Received JSON: \(jsonString)")
//            }
//            
//            do {
//                let decodedData = try JSONDecoder().decode(T.self, from: data)
//                DispatchQueue.main.async {
//                    completion(.success(decodedData))
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    completion(.failure(error))
//                }
//            }
//        }.resume()
//    }
    
    func request<T: Decodable>(
        endpoint: WooCommerceEndpoint,
        method: HTTPMethod,
        params: [String: String] = [:],
        body: [String: Any]? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        // Build URL with query parameters
        var components = URLComponents(string: "\(storeURL)\(endpoint.urlPath())")!
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Basic Auth header
        let loginString = "\(consumerKey):\(consumerSecret)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }

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
            }
            
            if let error = error {
                print("❌ Network Error: \(error.localizedDescription)")
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
                
                // Try to decode WooCommerce error response
                if let wooError = try? JSONDecoder().decode(WooErrorResponse.self, from: data) {
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

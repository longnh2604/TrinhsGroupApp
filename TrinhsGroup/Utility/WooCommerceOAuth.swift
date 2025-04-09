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

enum WooCommerceEndpoint {
    case authenticate
    case forgotPassword
    case customers
    case createCustomer
    case orders
    case products
    case specificOrder(orderID: Int)
    case specificProduct(productID: Int)

    func urlPath() -> String {
        switch self {
        case .authenticate:
            return "/wp-json/jwt-auth/v1/token"
        case .forgotPassword:
            return "/wp-login.php?action=lostpassword"
        case .createCustomer, .customers:
            return "/wp-json/wc/v3/customers"
        case .orders:
            return "/wp-json/wc/v3/orders"
        case .products:
            return "/wp-json/wc/v3/products"
        case .specificOrder(let orderID):
            return "/wp-json/wc/v3/orders/\(orderID)"
        case .specificProduct(let productID):
            return "/wp-json/wc/v3/products/\(productID)"
        }
    }
}

struct WooCommerceOAuth {
    private let consumerKey = "ck_d1cac0d2dbd173bb0e63c485cdf097a563ec6694"
    private let consumerSecret = "cs_213b91a11dae9aff0edbd0133e9b50155f82bd25"
    private let storeURL = "https://trinhsgroup.com.au"

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

        oauthParams.merge(params) { (_, new) in new }

        let sortedParams = oauthParams.sorted { $0.key < $1.key }
        let parameterString = sortedParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        let signatureBase = "\(httpMethod.rawValue)&" +
                            "\(baseURL.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)&" +
                            "\(parameterString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)"

        let signingKey = "\(consumerSecret)&"

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

    /// Generic API request function
    func request<T: Decodable>(
        endpoint: WooCommerceEndpoint,
        method: HTTPMethod,
        params: [String: String] = [:],
        body: [String: Any]? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var parameters = params
        let oauthSignature = generateOAuthSignature(httpMethod: method, endpoint: endpoint, params: parameters)
        parameters["oauth_signature"] = oauthSignature

        let queryString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let requestURL = URL(string: "\(storeURL)\(endpoint.urlPath())?\(queryString)")!

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received JSON: \(jsonString)")
            }
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedData))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
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
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 500, userInfo: nil)))
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(true))
            }
        }.resume()
    }
}

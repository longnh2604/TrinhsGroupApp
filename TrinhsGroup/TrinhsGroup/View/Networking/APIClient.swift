//
//  APIClient.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation
import SwiftyJSON

typealias requestCompletion = (_ success: Bool,_ error: String?) -> Void
typealias requestDataCompletion = (_ success: Bool,_ data: JSON?, _ error: String?) -> Void
typealias requestAnyArrDataCompletion = (_ success: Bool,_ data: [Any]?, _ error: String?) -> Void
typealias requestAnyDataCompletion = (_ success: Bool,_ data: Any?, _ error: String?) -> Void
typealias requestUserCompletion = (_ success: Bool,_ data: User?, _ error: String?) -> Void

class APIClient {
    static let shared = APIClient()
    init() {
        let MEMORY_CAPACITY = 4 * 1024 * 1024
        let DISK_CAPACITY =  20 * 1024 * 1024
        
        let cache = URLCache(memoryCapacity: MEMORY_CAPACITY, diskCapacity: DISK_CAPACITY, diskPath: nil)
        URLCache.shared = cache
    }
}

extension APIClient {
    
    func onCreateUser(username: String, password: String, email: String, completion: @escaping requestDataCompletion) {
        let fullNameArr = username.split(separator: " ")
        let firstName: String = String(fullNameArr[0])
        let lastName: String = fullNameArr.count > 1 ? String(fullNameArr[1]) : ""
        
        // Prepare URL"
        let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/customers?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)")
        guard let requestUrl = url else { fatalError() }
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        
        // HTTP Request Parameters which will be sent in HTTP Request Body
        let postString = "email=\(email)&username=\(username)&password=\(password)&first_name=\(firstName)&last_name=\(lastName)";
        // Set HTTP Request Body
        request.httpBody = postString.data(using: String.Encoding.utf8);
        // Perform HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                return
            }
            let json = JSON(data!)
            print(json)
            
            DispatchQueue.main.async {
                if json["message"].exists() {
                    completion(false, nil, json["message"].stringValue.html2AttributedString ?? "")
                } else {
                    completion(true, json, nil)
                }
            }
        }
        task.resume()
    }
    
    func onAuthUser(email: String, password: String, completion: @escaping requestDataCompletion) {
        // Prepare URL"
        let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/jwt-auth/v1/token")
        guard let requestUrl = url else { fatalError() }
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue(SECURITY_CODE, forHTTPHeaderField:"Security")
        
        // HTTP Request Parameters which will be sent in HTTP Request Body
        let postString = "username=\(email)&password=\(password)";
        // Set HTTP Request Body
        request.httpBody = postString.data(using: String.Encoding.utf8);
        // Perform HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                return
            }
            let json = JSON(data!)
            print(json)
            
            DispatchQueue.main.async {
                if json["message"].exists() {
                    completion(false, nil, json["message"].stringValue.html2AttributedString ?? "")
                } else {
                    completion(true, json, nil)
                }
            }
        }
        task.resume()
    }
    
    func onUpdateUser(user: User, password: String, completion: @escaping requestDataCompletion) {
        let json: [String: Any] = [
            "email": user.email,
            "password": password,
            "billing": [
                "first_name":user.billing.first_name,
                "last_name":user.billing.last_name,
                "country":user.billing.country,
                "address_1":user.billing.address_1,
                "city":user.billing.city,
                "postcode":user.billing.postcode,
                "state":user.billing.state,
                "email":user.billing.email,
                "phone":user.billing.phone
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
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                completion(false, nil, error.localizedDescription)
                return
            }
            let json = JSON(data!)
            print(json)
            completion(true, json, nil)
        }
        task.resume()
    }
    
    func onFetchUserInfo(id: Int, completion: @escaping requestUserCompletion) {
        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/customers/\(id)?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(User.self, from: data)
                    DispatchQueue.main.async {
                        completion(true, decodedResponse, nil)
                    }
                } catch DecodingError.keyNotFound(let key, let context) {
                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
                } catch DecodingError.valueNotFound(let type, let context) {
                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.typeMismatch(let type, let context) {
                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.dataCorrupted(let context) {
                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
                } catch let error as NSError {
                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
                }
                return
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            completion(false, nil, error?.localizedDescription)
        }.resume()
    }
    
    func onFetchCategories(completion: @escaping requestAnyArrDataCompletion) {
        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/products/categories?page=1&per_page=100&consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)&parent=0&order=asc") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) {data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode([Category].self, from: data)
                    DispatchQueue.main.async {
                        completion(true, decodedResponse, nil)
//                        self.categories.append(contentsOf: decodedResponse)
//                        self.selectedCategory = self.categories.first!
//                        self.fetchSelectedCategoryProducts()
                    }
                } catch DecodingError.keyNotFound(let key, let context) {
                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
                } catch DecodingError.valueNotFound(let type, let context) {
                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.typeMismatch(let type, let context) {
                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.dataCorrupted(let context) {
                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
                } catch let error as NSError {
                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
                }
                return
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            completion(false, nil, error?.localizedDescription)
        }.resume()
    }
    
    func onFetchSelectedCategoryProducts(id: Int, completion: @escaping requestAnyArrDataCompletion) {
        guard let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/products?page=1&per_page=100&category=\(id)&consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)&order=asc") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)

        URLSession.shared.dataTask(with: request) {data, response, error in
            if let data = data {

                if let decodedResponse = try? JSONDecoder().decode([Product].self, from: data) {
                    DispatchQueue.main.async {
                        completion(true, decodedResponse, nil)
                    }
                    return
                }
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            completion(false, nil, error?.localizedDescription)
        }.resume()
    }
    
    func onCreateOrder(user: User, paymentMethod: String, paymentMethodTitle: String, customerNote: String, status: String, productOrders: [ProductOrder], completion: @escaping requestAnyDataCompletion) {
        var lineItems:Array = [Dictionary<String, Any>]()
        
        for productOrder in productOrders{
            lineItems.append(["product_id" : productOrder.product_id, "quantity" : productOrder.quantity])
        }
        
        print(lineItems)
        
//        var shippingLines:Array = [Dictionary<String, Any>]()
//
//        for shippingOrder in shippingOrders {
//            shippingLines.append(["method_id" : shippingOrder.method_id, "total" : shippingOrder.total])
//        }
        
//        print(shippingLines)
        
        // prepare json data
        var json: [String: Any] = [
            "customer_id": user.id,
            "payment_method": paymentMethod,
            "payment_method_title": paymentMethodTitle,
            "customer_note": customerNote,
            "status": status,
            "billing": [
                "first_name":user.billing.first_name,
                "last_name":user.billing.last_name,
                "country":user.billing.country,
                "address_1":user.billing.address_1,
                "city":user.billing.city,
                "postcode":user.billing.postcode,
                "state":user.billing.state,
                "email":user.billing.email,
                "phone":user.billing.phone
            ],
//            "shipping": [
//                "first_name":user.shipping.first_name,
//                "last_name":user.shipping.last_name,
//                "company":user.shipping.company,
//                "country":user.shipping.country,
//                "address_1":user.shipping.address_1,
//                "address_2":user.shipping.address_2,
//                "city":user.shipping.city,
//                "postcode":user.shipping.postcode,
//                "state":user.shipping.state
//            ],
            "line_items": lineItems,
//            "shipping_lines": shippingLines
        ]
        
//        if coupon.id != Coupon.default.id {
//            json["coupon_lines"] = [["code": coupon.code]]
//        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        print(String(decoding: jsonData!, as: UTF8.self))
        
        // Prepare URL"
        let url = URL(string: "\(WOOCOMMERCE_URL)/wp-json/wc/v3/orders?consumer_key=\(CONSUMER_KEY)&consumer_secret=\(CONSUMER_SECRET_KEY)")
        guard let requestUrl = url else { fatalError() }
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        
        //HTTP Headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set HTTP Request Body
        request.httpBody = jsonData//postString.data(using: String.Encoding.utf8);
        // Perform HTTP Request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                return
            }
            let json = JSON(data!)
            print(json)
            
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(Order.self, from: data)
                    DispatchQueue.main.async {
                        print(decodedResponse)
                        DispatchQueue.main.async {
                            completion(true, decodedResponse, nil)
                        }
                        return
                    }
                } catch DecodingError.keyNotFound(let key, let context) {
                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
                } catch DecodingError.valueNotFound(let type, let context) {
                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.typeMismatch(let type, let context) {
                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.dataCorrupted(let context) {
                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
                } catch let error as NSError {
                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
                }
                return
            }
            print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            completion(false, nil, error?.localizedDescription)
        }
        task.resume()
    }
}

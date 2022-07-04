//
//  APIClient.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation
import SwiftyJSON

typealias requestCompletion = (_ success: Bool,_ error: String?) -> Void

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
    
    func onCreateUser(username: String, password: String, email: String, completion: @escaping requestCompletion) {
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
                    completion(false, json["message"].stringValue.html2AttributedString ?? "")
                } else {
                    completion(true, nil)
                }
            }
        }
        task.resume()
    }
    
}

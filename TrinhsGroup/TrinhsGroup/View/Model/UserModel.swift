//
//  UserModel.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation

struct User: Identifiable, Codable {
    var id: Int
    var email: String
    var username: String
    var first_name: String
    var last_name: String
    var password: String
    var billing: Billing
    var shipping: Shipping
    
    static var `default` : User {
        User(id: 0, email: "", username: "", first_name: "", last_name: "", password: "", billing: Billing.default, shipping: Shipping.default)
    }
}

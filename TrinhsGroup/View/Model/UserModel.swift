//
//  UserModel.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation

struct UserAuth: Codable {
    let token: String
    let email: String
    let username: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case token
        case email = "user_email"
        case username = "user_nicename"
        case displayName = "user_display_name"
    }
}

struct User: Identifiable, Codable {
    var id: Int
    var email: String
    var username: String
    var first_name: String
    var last_name: String
    var billing: Billing
    var shipping: Shipping
    var avatar_url: String?
    var is_paying_customer: Bool
    
    static var empty = User(
        id: 0,
        email: "",
        username: "",
        first_name: "",
        last_name: "",
        billing: Billing.empty,
        shipping: Shipping.empty,
        avatar_url: nil,
        is_paying_customer: false
    )
}

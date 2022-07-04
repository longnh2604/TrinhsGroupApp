//
//  BillingModel.swift
//  TrinhsGroup
//
//  Created by long on 04/07/2022.
//

import Foundation

struct Billing: Codable  {
    var first_name: String
    var last_name: String
    var company: String
    var country: String
    var address_1: String
    var address_2: String
    var city: String
    var postcode: String
    var state: String
    var email: String
    var phone: String
    
    static var `default` : Billing {
        Billing(first_name: "", last_name: "", company: "", country: "", address_1: "", address_2: "", city: "", postcode: "", state: "", email: "", phone: "")
    }
}

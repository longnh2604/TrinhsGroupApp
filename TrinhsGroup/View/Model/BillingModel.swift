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
    var country: String
    var address_1: String
    var city: String
    var postcode: String
    var state: String
    var email: String
    var phone: String
    var company: String
    
    static var empty = Billing(
        first_name: "", last_name: "", country: "", address_1: "", city: "", postcode: "", state: "", email: "", phone: "", company: ""
    )
    
    func checkFilledData() -> Bool {
        if first_name.isEmpty || last_name.isEmpty || country.isEmpty || address_1.isEmpty || city.isEmpty || postcode.isEmpty || state.isEmpty || email.isEmpty || phone.isEmpty {
            return false
        }
        return true
    }
}

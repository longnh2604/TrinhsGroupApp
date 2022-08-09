//
//  CouponModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct Coupon: Codable, Identifiable {
    var status: String?
    var code: String?
    var message: String?
    var id: Int?
    var discount_type: String?
    var amount: String?
    var minimum_amount: String?
    var maximum_amount: String?
    
    var isPercent: Bool {
        if discount_type == "percent" {
            return true
        }
        return false
    }
    
    static var `default` : Coupon {
        Coupon(status: "", code: "", message: "", id: -1, discount_type: "", amount: "", minimum_amount: "", maximum_amount: "")
    }
}

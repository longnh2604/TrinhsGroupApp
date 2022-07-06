//
//  CouponModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct Coupon: Codable{
    var status: String?
    var code: String?
    var message: String?
    var id: Int?
    var type: String?
    var amount: String?
    var minimum_amount: String?
    var maximum_amount: String?
    
    static var `default` : Coupon {
        Coupon(status: "", code: "", message: "", id: -1, type: "", amount: "", minimum_amount: "", maximum_amount: "")
    }
}

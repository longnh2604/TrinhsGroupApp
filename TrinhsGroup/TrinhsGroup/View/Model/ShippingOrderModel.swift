//
//  ShippingOrderModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct ShippingOrder: Codable{
    var method_id: String
    var total: String
    
    static var `default` : ShippingOrder {
        ShippingOrder(method_id: "", total: "0")
    }
}

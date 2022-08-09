//
//  OrderModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct Order: Identifiable, Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id, number, status, date_created, date_modified, discount_total, total, customer_note, billing, shipping, payment_method_title, line_items, shipping_lines
    }
    
    var id: Int
    var number: String
    var status: String
    var date_created: String
    var date_modified: String
    var discount_total: String
    var total: String
    var customer_note: String
    var billing: Billing
    var shipping: Shipping
    var payment_method_title: String
    var line_items = [ProductOrder]()
    var shipping_lines = [ShippingOrder]()
    
    var isCancelled: Bool {
        return status == "cancelled" ? true : false
    }
    
    var subtotal: Double {
        if line_items.count > 0 {
            return line_items.reduce(0) { $0 + (Double($1.subtotal)!) }
        } else {
            return 0
        }
    }
    
    static var `default` : Order {
        Order(id: 0, number: "", status: "on-hold", date_created: "", date_modified: "", discount_total: "0", total: "0", customer_note: "", billing: Billing.default, shipping: Shipping.default, payment_method_title: "",line_items: [ProductOrder.default], shipping_lines: [ShippingOrder.default])
    }
}

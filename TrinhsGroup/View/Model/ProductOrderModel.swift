//
//  ProductOrderModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct ProductOrder: Identifiable, Codable {
    var id: Int
    var product_id: Int
    var name: String
    var quantity: Int
    var subtotal: String
    var total: Double
    var price: Double
    var meta_data = [ProductMetaData]()
    /// Sent as `yith_wapo`, which is what buys the add-ons — `meta_data` alone was accepted as
    /// text and charged nothing (order 11690).
    var addOnChoices = [AddOnChoice]()

    static var `default` : ProductOrder {
        ProductOrder(id: 0, product_id: 0, name: "", quantity: 0, subtotal: "0", total: 0, price: 0, meta_data: [], addOnChoices: [])
    }
}

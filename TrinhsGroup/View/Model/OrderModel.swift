//
//  OrderModel.swift
//  TrinhsGroup
//
//  Created by long on 06/07/2022.
//

import Foundation

struct Order: Identifiable, Codable {
    var id: Int
    var number: String
    var status: String
    var dateCreated: String
    var dateModified: String
    var discountTotal: String
    var total: String
    var customerNote: String
    var billing: Billing
    var shipping: Shipping
    var paymentMethodTitle: String
    var lineItems: [LineItem]
    var shippingLines: [ShippingLine]

    private enum CodingKeys: String, CodingKey {
        case id, number, status
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case discountTotal = "discount_total"
        case total
        case customerNote = "customer_note"
        case billing, shipping
        case paymentMethodTitle = "payment_method_title"
        case lineItems = "line_items"
        case shippingLines = "shipping_lines"
    }

    var subtotal: Double {
        lineItems.reduce(0) { $0 + (Double($1.subtotal) ?? 0) }
    }

    static var `default`: Order {
        Order(
            id: 0,
            number: "",
            status: "on-hold",
            dateCreated: "",
            dateModified: "",
            discountTotal: "0",
            total: "0",
            customerNote: "",
            billing: Billing.empty,
            shipping: Shipping.empty,
            paymentMethodTitle: "",
            lineItems: [],
            shippingLines: []
        )
    }
}

struct LineItem: Codable {
    var id: Int
    var name: String
    var productId: Int
    var quantity: Int
    var subtotal: String
    var total: String
    var price: Double

    private enum CodingKeys: String, CodingKey {
        case id, name
        case productId = "product_id"
        case quantity, subtotal, total, price
    }

    static var `default`: LineItem {
        LineItem(
            id: 0,
            name: "",
            productId: 0,
            quantity: 0,
            subtotal: "0",
            total: "0",
            price: 0
        )
    }
}

struct ShippingLine: Codable {
    // Add properties based on your shipping_lines JSON structure
    static var `default`: ShippingLine {
        ShippingLine()
    }
}

// Keep your existing Billing and Shipping structs

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

    /// Order-level fees. The app's 5% discount arrives as a negative fee line, never as
    /// `discount_total`, which carries voucher discounts only.
    ///
    /// Optional because the plugin adds `fee_lines` only when the discount is non-zero, and
    /// Swift's synthesised decoder throws on a missing key for a non-optional property.
    var feeLines: [FeeLine]?

    // NEW (optional but important)
    var paymentURL: String?      // <- add this
    var orderKey: String?        // <- optional, sometimes useful

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
        case feeLines = "fee_lines"
        // NEW
        case paymentURL = "payment_url"
        case orderKey   = "order_key"
    }

    // Convenience: numeric discount value
    var discount: Double {
        Double(discountTotal) ?? 0
    }

    /// Fees, defaulting to none. Prefer this over `feeLines` at every call site.
    var fees: [FeeLine] {
        feeLines ?? []
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
            shippingLines: [],
            feeLines: nil,
            paymentURL: nil,
            orderKey: nil
        )
    }
}

struct LineItem: Codable, Identifiable {
    var id: Int
    var name: String
    var productId: Int
    var quantity: Int
    var subtotal: String
    var total: String
    var price: Double
    /// Add-on selections and the customer's note, exactly as the app sent them at checkout.
    /// Snake-cased to match `ProductOrder.meta_data`, the outbound model it mirrors.
    var meta_data: [ProductMetaData] = []

    private enum CodingKeys: String, CodingKey {
        case id, name
        case productId = "product_id"
        case quantity, subtotal, total, price
        case meta_data
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

// In an extension, not in the struct body, so the memberwise initialiser survives —
// `LineItem.default` and the previews call it.
extension LineItem {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id        = try container.decode(Int.self, forKey: .id)
        name      = try container.decode(String.self, forKey: .name)
        productId = try container.decode(Int.self, forKey: .productId)
        quantity  = try container.decode(Int.self, forKey: .quantity)
        subtotal  = try container.decode(String.self, forKey: .subtotal)
        total     = try container.decode(String.self, forKey: .total)
        price     = try container.decode(Double.self, forKey: .price)
        // `try?` on purpose. Swift's synthesised decoder ignores default values and throws on
        // a missing key, and Woo omits meta_data on plain products. Beyond that, this model is
        // nested inside Order: a line of add-on labels is not worth failing a customer's whole
        // order history over.
        meta_data = (try? container.decodeIfPresent([ProductMetaData].self, forKey: .meta_data)) ?? []
    }

    /// Add-on selections, customer-facing only.
    ///
    /// WooCommerce's internal line-item meta is underscore-prefixed (`_note`,
    /// `_reduced_stock`) and must never render as something the customer chose.
    var addOns: [ProductMetaData] {
        meta_data.filter { !$0.key.hasPrefix("_") }
    }

    /// What the customer actually chose, one entry per option group, in the order the
    /// server listed them.
    ///
    /// The two order paths spell an add-on the opposite way round:
    ///
    /// - Web (YITH) puts the group label in the key and the choice in the value —
    ///   `"1st Pho"` / `"Beef"`. A ticked checkbox group repeats the key once per option,
    ///   so `"Addition"` arrives three times with three different values; grouping is what
    ///   turns that into one readable line.
    /// - The app puts the choice in the key and its price in the value —
    ///   `"Extra beef"` / `"3"` (see `ProductDetailsCard.AddToCartButton`).
    ///
    /// So a value that parses as a number is a price, never a label, and is dropped —
    /// rendering it would show a charge that the app path never actually billed. An empty
    /// value means YITH stored the option without a display value, and there too the key is
    /// the choice. Either way the group falls back to showing just its key.
    var addOnLabels: [String] {
        var groups: [String] = []
        var choices: [String: [String]] = [:]

        for meta in addOns {
            if choices[meta.key] == nil {
                groups.append(meta.key)
                choices[meta.key] = []
            }
            let chosen = meta.value.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !chosen.isEmpty, Double(chosen) == nil else { continue }
            choices[meta.key]?.append(chosen)
        }

        return groups.map { key in
            guard let picked = choices[key], !picked.isEmpty else { return key }
            return "\(key): \(picked.joined(separator: ", "))"
        }
    }

    /// The customer's free-text note for this line.
    ///
    /// Blank reads as absent so the card does not draw an empty pair of quotes.
    var note: String? {
        guard let raw = meta_data.first(where: { $0.key == "_note" })?.value.stringValue,
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return raw
    }
}

struct FeeLine: Codable {
    var name: String
    var total: String

    /// Negative for a discount, which is how the app's 5% is applied.
    var amount: Double {
        Double(total) ?? 0
    }

    static var `default`: FeeLine {
        FeeLine(name: "", total: "0")
    }
}

struct ShippingLine: Codable {
    // Add properties based on your shipping_lines JSON structure
    static var `default`: ShippingLine {
        ShippingLine()
    }
}

// Keep your existing Billing and Shipping structs

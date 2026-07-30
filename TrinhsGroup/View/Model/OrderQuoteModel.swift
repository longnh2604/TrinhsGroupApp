//
//  OrderQuoteModel.swift
//  TrinhsGroup
//
//  Wire type for POST /wp-json/trinh-app/v1/me/orders/preview.
//
//  The checkout screen cannot work its own total out any more, and should not try: add-on
//  prices come from YITH and the cash-on-pickup discount is a negative gateway fee configured
//  on the website, so neither exists until the server has built a cart. This is that cart,
//  priced, without an order being created.
//
//  `fee_lines` is the same shape as an order's, so the discount row renders from the server's
//  own label with no rate held in the app.
//

import Foundation

struct OrderQuote: Codable {
    var subtotal: String
    var discountTotal: String
    var feeLines: [FeeLine]?
    var total: String

    private enum CodingKeys: String, CodingKey {
        case subtotal, total
        case discountTotal = "discount_total"
        case feeLines = "fee_lines"
    }

    /// Fees, defaulting to none. Prefer this over `feeLines` at every call site.
    var fees: [FeeLine] {
        feeLines ?? []
    }

    var subtotalValue: Double {
        Double(subtotal) ?? 0
    }

    var discountValue: Double {
        Double(discountTotal) ?? 0
    }

    var totalValue: Double {
        Double(total) ?? 0
    }

    static var `default`: OrderQuote {
        OrderQuote(subtotal: "0", discountTotal: "0", feeLines: nil, total: "0")
    }
}

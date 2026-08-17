package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Wire type for POST /wp-json/trinh-app/v1/me/orders/preview.
 * Mirrors Swift's OrderQuote struct in OrderQuoteModel.swift.
 *
 * The checkout screen cannot work its own total out any more, and should not try: add-on
 * prices come from YITH and the cash-on-pickup discount is a negative gateway fee configured
 * on the website, so neither exists until the server has built the cart. This is that cart,
 * priced, without an order being created.
 */
@Serializable
data class OrderQuote(
    val subtotal: String = "0",
    @SerialName("discount_total") val discountTotal: String = "0",
    @SerialName("fee_lines") val feeLines: List<FeeLine>? = null,
    val total: String = "0"
) {
    /** Fees, defaulting to none. Prefer this over [feeLines] at the call site. */
    val fees: List<FeeLine> get() = feeLines ?: emptyList()

    val subtotalValue: Double get() = subtotal.toDoubleOrNull() ?: 0.0
    val discountValue: Double get() = discountTotal.toDoubleOrNull() ?: 0.0
    val totalValue: Double get() = total.toDoubleOrNull() ?: 0.0

    companion object {
        val Empty = OrderQuote()
    }
}

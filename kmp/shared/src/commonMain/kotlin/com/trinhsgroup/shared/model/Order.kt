package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a WooCommerce order.
 * Mirrors the Swift Order struct in OrderModel.swift.
 */
@Serializable
data class Order(
    val id: Int,
    val number: String,
    val status: String,
    @SerialName("date_created") val dateCreated: String,
    @SerialName("date_modified") val dateModified: String,
    @SerialName("discount_total") val discountTotal: String,
    val total: String,
    @SerialName("customer_note") val customerNote: String,
    val billing: Billing,
    val shipping: Shipping,
    @SerialName("payment_method_title") val paymentMethodTitle: String,
    @SerialName("line_items") val lineItems: List<LineItem>,
    @SerialName("shipping_lines") val shippingLines: List<ShippingLine>,
    /**
     * Order-level fees, each rendered with the server's own label. `discount_total` is separate
     * and carries voucher discounts only.
     *
     * Orders placed before the app's 5% discount was withdrawn still carry it here as a
     * negative fee line, so this has to keep decoding.
     */
    @SerialName("fee_lines") val feeLines: List<FeeLine>? = null,
    @SerialName("payment_url") val paymentURL: String? = null,
    @SerialName("order_key") val orderKey: String? = null
) {
    /**
     * Convenience: numeric discount value.
     * Mirrors Swift's discount computed property.
     */
    /** Fees, defaulting to none. Prefer this over [feeLines] at every call site. */
    val fees: List<FeeLine>
        get() = feeLines ?: emptyList()

    val discount: Double
        get() = discountTotal.toDoubleOrNull() ?: 0.0

    /**
     * Calculates the subtotal from line items.
     * Mirrors Swift's subtotal computed property.
     */
    val subtotal: Double
        get() = lineItems.sumOf { it.subtotal.toDoubleOrNull() ?: 0.0 }

    companion object {
        val Default = Order(
            id = 0,
            number = "",
            status = "on-hold",
            dateCreated = "",
            dateModified = "",
            discountTotal = "0",
            total = "0",
            customerNote = "",
            billing = Billing.Empty,
            shipping = Shipping.Empty,
            paymentMethodTitle = "",
            lineItems = emptyList(),
            shippingLines = emptyList(),
            paymentURL = null,
            orderKey = null
        )
    }
}

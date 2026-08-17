package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a line item in a WooCommerce order.
 * Mirrors the Swift LineItem struct in OrderModel.swift.
 */
@Serializable
data class LineItem(
    val id: Int,
    val name: String,
    @SerialName("product_id") val productId: Int,
    val quantity: Int,
    val subtotal: String,
    val total: String,
    val price: Double
) {
    companion object {
        val Default = LineItem(
            id = 0,
            name = "",
            productId = 0,
            quantity = 0,
            subtotal = "0",
            total = "0",
            price = 0.0
        )
    }
}

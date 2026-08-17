package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a product in an order request.
 * Mirrors the Swift ProductOrder struct in ProductOrderModel.swift.
 */
@Serializable
data class ProductOrder(
    val id: Int,
    @SerialName("product_id") val productId: Int,
    val name: String,
    val quantity: Int,
    val subtotal: String,
    val total: Double,
    val price: Double,
    @SerialName("meta_data") val metaData: List<ProductMetaData> = emptyList()
) {
    companion object {
        val Default = ProductOrder(
            id = 0,
            productId = 0,
            name = "",
            quantity = 0,
            subtotal = "0",
            total = 0.0,
            price = 0.0,
            metaData = emptyList()
        )
    }
}

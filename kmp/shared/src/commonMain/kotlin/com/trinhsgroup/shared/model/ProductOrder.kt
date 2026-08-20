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
    @SerialName("meta_data") val metaData: List<ProductMetaData> = emptyList(),
    /** Picked YITH options, submitted as `yith_wapo` so the server prices the line. */
    val addOnChoices: List<AddOnChoice> = emptyList()
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

/**
 * The one description of a basket, shared by the quote and the order, so the figure quoted and
 * the figure ordered cannot come from different baskets.
 *
 * The add-on choices have to travel with it: they are what `yith_wapo` is built from, and
 * without them the server prices the line as if nothing had been picked.
 */
fun List<Product>.toProductOrders(): List<ProductOrder> = map { item ->
    ProductOrder(
        id = 0,
        productId = item.id,
        name = item.name,
        quantity = item.quantity,
        subtotal = "",
        total = item.regularPrice,
        price = item.regularPrice,
        metaData = item.metaData,
        addOnChoices = item.addOnChoices
    )
}

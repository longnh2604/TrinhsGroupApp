package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents shipping information for an order request.
 * Mirrors the Swift ShippingOrder struct in ShippingOrderModel.swift.
 */
@Serializable
data class ShippingOrder(
    @SerialName("method_id") val methodId: String,
    val total: String
) {
    companion object {
        val Default = ShippingOrder(
            methodId = "",
            total = "0"
        )
    }
}

package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

/**
 * Represents a shipping line in a WooCommerce order.
 * Mirrors the Swift ShippingLine struct in OrderModel.swift.
 */
@Serializable
data class ShippingLine(
    val id: Int? = null,
    val methodId: String? = null,
    val methodTitle: String? = null,
    val total: String? = null
) {
    companion object {
        val Default = ShippingLine()
    }
}

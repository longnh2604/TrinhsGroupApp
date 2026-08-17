package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a WooCommerce coupon.
 * Mirrors the Swift Coupon struct.
 */
@Serializable
data class Coupon(
    val status: String? = null,
    val code: String? = null,
    val message: String? = null,
    val id: Int? = null,
    val type: String? = null,
    val amount: String? = null,
    @SerialName("minimum_amount") val minimumAmount: String? = null,
    @SerialName("maximum_amount") val maximumAmount: String? = null
) {
    companion object {
        val Default = Coupon(
            status = "",
            code = "",
            message = "",
            id = -1,
            type = "",
            amount = "",
            minimumAmount = "",
            maximumAmount = ""
        )
    }
}

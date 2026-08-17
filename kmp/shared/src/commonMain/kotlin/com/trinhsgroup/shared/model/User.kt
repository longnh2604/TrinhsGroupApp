package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * JWT authentication response.
 * Mirrors Swift's UserAuth struct.
 */
@Serializable
data class UserAuth(
    val token: String,
    @SerialName("user_email") val email: String,
    @SerialName("user_nicename") val username: String,
    @SerialName("user_display_name") val displayName: String
)

/**
 * Reply from the server-side signup route.
 * Mirrors Swift's RegistrationResponse in AuthServices.swift.
 */
@Serializable
data class RegistrationResponse(
    val success: Boolean = false,
    val id: Int = 0,
    val email: String = ""
)

/**
 * WooCommerce customer/user model.
 * Mirrors Swift's User struct.
 */
@Serializable
data class User(
    val id: Int = 0,
    val email: String = "",
    val username: String = "",
    @SerialName("first_name") val firstName: String = "",
    @SerialName("last_name") val lastName: String = "",
    val billing: Billing = Billing.Empty,
    val shipping: Shipping = Shipping.Empty,
    @SerialName("avatar_url") val avatarUrl: String? = null,
    @SerialName("is_paying_customer") val isPayingCustomer: Boolean = false
) {
    companion object {
        val Empty = User()
    }
}

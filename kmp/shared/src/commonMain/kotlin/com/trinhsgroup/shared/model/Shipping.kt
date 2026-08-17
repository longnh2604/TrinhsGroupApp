package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Shipping(
    @SerialName("first_name") val firstName: String = "",
    @SerialName("last_name") val lastName: String = "",
    val company: String = "",
    val country: String = "",
    @SerialName("address_1") val address1: String = "",
    val phone: String = "",
    val city: String = "",
    val postcode: String = "",
    val state: String = ""
) {
    companion object {
        val Empty = Shipping()
    }
}

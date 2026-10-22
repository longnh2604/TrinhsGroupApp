package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Billing(
    @SerialName("first_name") val firstName: String = "",
    @SerialName("last_name") val lastName: String = "",
    val country: String = "",
    @SerialName("address_1") val address1: String = "",
    val city: String = "",
    val postcode: String = "",
    val state: String = "",
    val email: String = "",
    val phone: String = "",
    val company: String = ""
) {
    fun checkFilledData(): Boolean {
        if (firstName.isEmpty() || lastName.isEmpty() || country.isEmpty() ||
            address1.isEmpty() || city.isEmpty() || postcode.isEmpty() ||
            state.isEmpty() || email.isEmpty() || phone.isEmpty()
        ) return false
        return true
    }

    /**
     * What an order needs: a number the kitchen can ring back to confirm it, and an address.
     * Country isn't asked (the store is Australia only), and name and email come from the account.
     */
    fun isReadyToOrder(): Boolean =
        listOf(phone, address1, city, postcode, state).all { it.isNotBlank() }

    companion object {
        val Empty = Billing()
    }
}

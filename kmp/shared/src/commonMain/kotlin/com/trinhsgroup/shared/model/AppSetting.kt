package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class AppSetting(
    val status: String,
    val code: String,
    @SerialName("currency_symbol") val currencySymbol: String,
    @SerialName("currency_position") val currencyPosition: String,
    @SerialName("thousand_separator") val thousandSeparator: String,
    @SerialName("decimal_separator") val decimalSeparator: String,
    @SerialName("number_of_decimals") val numberOfDecimals: String
)

@Serializable
data class PasswordResetResponse(
    val message: String
)

package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

/**
 * A fee line on an order or an order quote.
 * Mirrors Swift's FeeLine struct in OrderModel.swift.
 *
 * The server labels these itself, so the app renders whatever comes back rather than
 * holding a rate of its own — the cash-on-pickup discount arrives here as a negative fee.
 */
@Serializable
data class FeeLine(
    val name: String = "",
    val total: String = "0"
) {
    /** Negative for a discount. */
    val amount: Double get() = total.toDoubleOrNull() ?: 0.0

    companion object {
        val Default = FeeLine()
    }
}

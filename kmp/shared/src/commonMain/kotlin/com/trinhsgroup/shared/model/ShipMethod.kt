package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Cost(
    val id: String,
    val value: String
)

@Serializable
data class ShipSettings(
    val cost: Cost
)

@Serializable
data class ShipMethod(
    val id: Int,
    val title: String,
    val enabled: Boolean,
    @SerialName("method_id") val methodId: String,
    @SerialName("method_title") val methodTitle: String,
    val settings: ShipSettings
) {
    companion object {
        val Default = ShipMethod(
            id = 0,
            title = "Pickup",
            enabled = true,
            methodId = "",
            methodTitle = "",
            settings = ShipSettings(cost = Cost(id = "", value = "0"))
        )
    }
}

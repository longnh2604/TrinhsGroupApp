package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

@Serializable
data class Zone(
    val id: Int,
    val name: String
)

package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

@Serializable
data class Attribute(
    val id: Int,
    val name: String,
    val options: List<String> = emptyList()
)

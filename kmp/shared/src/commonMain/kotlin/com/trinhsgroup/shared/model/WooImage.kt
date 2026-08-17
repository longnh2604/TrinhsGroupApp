package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

@Serializable
data class WooImage(
    val id: Int,
    val src: String
)

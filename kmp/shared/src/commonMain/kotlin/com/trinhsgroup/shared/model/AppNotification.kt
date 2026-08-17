package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

@Serializable
data class AppNotification(
    val id: Int,
    val title: String,
    val content: String
)

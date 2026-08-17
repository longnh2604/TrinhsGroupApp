package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

@Serializable
data class Slider(
    val id: Int,
    val title: String,
    val image: String
) {
    companion object {
        val Default = Slider(
            id = 0,
            title = "",
            image = "https://asilarslan.com/grocery/wp-content/uploads/2021/04/close-up-man-delivering-food-2-e1618696795311.png"
        )
    }
}

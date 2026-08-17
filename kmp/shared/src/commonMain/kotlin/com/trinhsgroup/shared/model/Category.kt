package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

@Serializable
data class Category(
    val id: Int,
    val image: WooImage? = null,
    val name: String
) {
    companion object {
        val Default = Category(
            id = 0,
            image = WooImage(id = 0, src = "https://asilarslan.com/trendy/wp-content/uploads/2021/04/pexels-apostolos-vamvouras-2285500.jpg"),
            name = ""
        )
    }
}

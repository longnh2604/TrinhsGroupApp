package com.trinhsgroup.shared.model

data class AppEvent(
    val id: Int = 0,
    val content: String = "",
    val type: String = "",
    val title: String = "",
    val link: String = "",
    val imgURL: String = ""
) {
    companion object {
        fun fromMap(dic: Map<String, Any?>): AppEvent = AppEvent(
            id = (dic["id"] as? Number)?.toInt() ?: 0,
            content = dic["content"] as? String ?: "",
            type = dic["type"] as? String ?: "",
            imgURL = dic["imgURL"] as? String ?: "",
            title = dic["title"] as? String ?: "",
            link = dic["link"] as? String ?: ""
        )
    }
}

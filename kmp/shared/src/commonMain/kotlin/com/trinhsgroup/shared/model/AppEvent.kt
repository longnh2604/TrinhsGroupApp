package com.trinhsgroup.shared.model

/**
 * A Home carousel event, as stored in the Firestore `events` collection.
 * Mirrors iOS AppEvent. Field notes live in docs/firestore-events.md.
 */
data class AppEvent(
    val id: Int = 0,
    val title: String = "",
    /** Card artwork; the card draws its own wording over it, so it carries no text. */
    val imgURL: String = "",
    /** Small caps line above the title, e.g. "FAMILY SHARING". */
    val eyebrow: String = "",
    /** Price or summary line under the title. */
    val subtitle: String = "",
    /** Text inside the highlighted chip along the bottom of the card. */
    val detail: String = "",
    /** Full poster, opened when the card is tapped. Empty makes the card untappable. */
    val posterURL: String = "",
    /** Off takes the event out of the carousel without deleting the document. */
    val active: Boolean = true,
    /**
     * An offer only the app has. Gets its own badge and sorts ahead of the general events,
     * so an app-only special is the first card a customer sees. Absent counts as off.
     */
    val appOnly: Boolean = false
) {
    /** The wording is part of the artwork on the poster, so spell the card out for screen readers. */
    val accessibilityLabel: String
        get() = listOf(if (appOnly) APP_ONLY_BADGE else "", eyebrow, title, subtitle, detail)
            .filter { it.isNotEmpty() }
            .joinToString(". ")

    companion object {
        /** One spelling, used by the badge and by TalkBack. */
        const val APP_ONLY_BADGE = "App exclusive"

        /** Carousel order: app-only offers first, id order within each half. */
        val inBannerOrder: Comparator<AppEvent> =
            compareBy({ if (it.appOnly) 0 else 1 }, { it.id })

        fun fromMap(dic: Map<String, Any?>): AppEvent = AppEvent(
            // A document written with the id as a string still sorts correctly.
            id = (dic["id"] as? Number)?.toInt() ?: (dic["id"] as? String)?.toIntOrNull() ?: 0,
            title = dic["title"] as? String ?: "",
            imgURL = dic["imgURL"] as? String ?: "",
            eyebrow = dic["eyebrow"] as? String ?: "",
            subtitle = dic["subtitle"] as? String ?: "",
            detail = dic["detail"] as? String ?: "",
            posterURL = dic["posterURL"] as? String ?: "",
            // Absent counts as on, so documents written before the field existed still show.
            active = dic["active"] as? Boolean ?: true,
            appOnly = dic["appOnly"] as? Boolean ?: false
        )
    }
}

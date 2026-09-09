package com.trinhsgroup.shared.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * The Firestore fields behind the Home carousel, and the FB-6 app-only offer.
 *
 * Worth pinning: the events are edited in a console, not in code, so a document written
 * before a field existed has to keep rendering as it did — and the badge wording is drawn
 * by the app, so TalkBack only reads it if the label says it.
 */
class AppEventTest {

    private fun event(id: Int, appOnly: Boolean? = null): AppEvent {
        val dic = mutableMapOf<String, Any?>("id" to id, "title" to "T$id")
        if (appOnly != null) dic["appOnly"] = appOnly
        return AppEvent.fromMap(dic)
    }

    @Test
    fun `absent appOnly counts as a general event`() {
        assertFalse(event(1).appOnly)
        assertTrue(event(1, appOnly = true).appOnly)
    }

    @Test
    fun `app-only offers sort ahead of general events`() {
        val ordered = listOf(
            event(1),
            event(9, appOnly = true),
            event(2),
            event(4, appOnly = true)
        ).sortedWith(AppEvent.inBannerOrder)

        assertEquals(listOf(4, 9, 1, 2), ordered.map { it.id })
    }

    @Test
    fun `the badge is spoken, since its wording is not in the artwork either`() {
        val dic = mutableMapOf<String, Any?>(
            "id" to 1,
            "title" to "Banh mi week",
            "eyebrow" to "FAMILY",
            "appOnly" to true
        )
        assertEquals("App exclusive. FAMILY. Banh mi week", AppEvent.fromMap(dic).accessibilityLabel)

        dic["appOnly"] = false
        assertEquals("FAMILY. Banh mi week", AppEvent.fromMap(dic).accessibilityLabel)
    }
}

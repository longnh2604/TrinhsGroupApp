package com.trinhsgroup.shared.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The notification history's whole rule set. NotificationStore only adds persistence around it.
 */
class AppNotificationTest {

    private fun push(id: String, date: Long = 0L, isRead: Boolean = false, orderId: Int? = null) =
        AppNotification(id = id, title = "Order update", content = "Ready", date = date, isRead = isRead, orderId = orderId)

    @Test
    fun `a push that arrives and is then tapped is one entry`() {
        val history = listOf<AppNotification>()
            .upsert(push("msg-1"))
            .upsert(push("msg-1", isRead = true))

        assertEquals(1, history.size)
        assertTrue(history.single().isRead)
    }

    @Test
    fun `a delivery never un-reads an entry`() {
        val history = listOf(push("msg-1", isRead = true)).upsert(push("msg-1", isRead = false))

        assertTrue(history.single().isRead)
    }

    @Test
    fun `an entry stored without an order id picks one up`() {
        val history = listOf(push("msg-1")).upsert(push("msg-1", orderId = 4321))

        assertEquals(4321, history.single().orderId)
    }

    @Test
    fun `newest first`() {
        val history = listOf<AppNotification>()
            .upsert(push("old", date = 1_000L))
            .upsert(push("new", date = 2_000L))

        assertEquals(listOf("new", "old"), history.map { it.id })
    }

    /** An empty payload would be a row with nothing in it, and iOS drops those too. */
    @Test
    fun `a push with no title and no body is not stored`() {
        val history = listOf<AppNotification>()
            .upsert(AppNotification(id = "msg-1", title = "", content = ""))

        assertTrue(history.isEmpty())
    }

    @Test
    fun `an unread count is the entries not yet read`() {
        val history = listOf<AppNotification>()
            .upsert(push("a", date = 1L))
            .upsert(push("b", date = 2L, isRead = true))

        assertEquals(1, history.count { !it.isRead })
        assertNull(history.first { it.id == "a" }.orderId)
    }
}

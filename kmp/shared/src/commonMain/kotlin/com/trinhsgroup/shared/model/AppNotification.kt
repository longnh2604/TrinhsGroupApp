package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

/**
 * One push the app has seen, as the bell screen shows it.
 * Mirrors Swift's AppNotification.
 *
 * @param id the message id, so the same push arriving twice is one entry
 * @param date when it arrived, epoch millis; the list reads newest first
 * @param orderId the order this is about, when the push carried one. Null entries are not
 *                tappable — there is nothing to open.
 */
@Serializable
data class AppNotification(
    val id: String,
    val title: String,
    val content: String,
    val date: Long = 0L,
    val isRead: Boolean = false,
    val orderId: Int? = null
)

/**
 * Adds a notification, or reconciles the one already stored under this id.
 *
 * Kept as a pure function because it holds every rule worth getting wrong: a push that
 * arrives while the app is open and is then tapped must not appear twice, a tap must be able
 * to mark an existing entry read, and an entry stored before it carried an order id has to be
 * able to pick one up so it becomes tappable.
 */
fun List<AppNotification>.upsert(notification: AppNotification): List<AppNotification> {
    if (notification.title.isEmpty() && notification.content.isEmpty()) return this

    if (none { it.id == notification.id }) {
        return (this + notification).sortedByDescending { it.date }
    }

    return map {
        if (it.id != notification.id) it
        else it.copy(
            isRead = it.isRead || notification.isRead,
            orderId = it.orderId ?: notification.orderId
        )
    }
}

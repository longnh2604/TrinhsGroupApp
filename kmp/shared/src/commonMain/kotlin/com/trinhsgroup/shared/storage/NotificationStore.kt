package com.trinhsgroup.shared.storage

import com.trinhsgroup.shared.model.AppNotification
import com.trinhsgroup.shared.model.upsert
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Every push the app has seen, persisted, newest first.
 * Mirrors Swift's NotificationStore.
 *
 * The system tray is not the history: it is cleared by the OS and by the customer. This is
 * what the bell screen reads, and what its unread badge counts.
 */
class NotificationStore(private val keyValueStore: KeyValueStore) {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    private val _notifications = MutableStateFlow(load())
    val notifications: StateFlow<List<AppNotification>> = _notifications.asStateFlow()

    /**
     * Records an arrival, or reconciles the entry already stored under this id.
     *
     * @param isRead true when this is a tap rather than a delivery
     */
    fun add(
        id: String,
        title: String,
        content: String,
        date: Long,
        isRead: Boolean = false,
        orderId: Int? = null
    ) {
        val updated = _notifications.value.upsert(
            AppNotification(
                id = id,
                title = title,
                content = content,
                date = date,
                isRead = isRead,
                orderId = orderId
            )
        )
        if (updated != _notifications.value) persist(updated)
    }

    fun markRead(id: String) {
        persist(_notifications.value.map { if (it.id == id) it.copy(isRead = true) else it })
    }

    fun markAllRead() {
        if (_notifications.value.none { !it.isRead }) return
        persist(_notifications.value.map { it.copy(isRead = true) })
    }

    fun remove(id: String) {
        persist(_notifications.value.filterNot { it.id == id })
    }

    private fun load(): List<AppNotification> {
        val stored = keyValueStore.getString(KEY)
        if (stored.isEmpty()) return emptyList()
        return try {
            json.decodeFromString<List<AppNotification>>(stored).sortedByDescending { it.date }
        } catch (e: Exception) {
            println("🔔 NotificationStore: unreadable history discarded (${e.message})")
            emptyList()
        }
    }

    private fun persist(notifications: List<AppNotification>) {
        _notifications.value = notifications
        keyValueStore.putString(KEY, json.encodeToString(notifications))
    }

    private companion object {
        const val KEY = "allNotifications"
    }
}

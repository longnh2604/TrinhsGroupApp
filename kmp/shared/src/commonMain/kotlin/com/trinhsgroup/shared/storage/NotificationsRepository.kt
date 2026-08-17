package com.trinhsgroup.shared.storage

import com.trinhsgroup.shared.model.AppNotification
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Repository for managing notifications.
 * Mirrors Swift's UserDefaultsManager notifications functionality.
 */
class NotificationsRepository(private val keyValueStore: KeyValueStore) {

    companion object {
        private const val ALL_NOTIFICATIONS_KEY = "allNotifications"
        private const val NEW_NOTIFICATIONS_KEY = "newNotifications"
    }

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    // MARK: - All Notifications

    /**
     * Loads all notifications.
     * Mirrors Swift's load().
     */
    fun load(): List<AppNotification> {
        val jsonString = keyValueStore.getString(ALL_NOTIFICATIONS_KEY)
        if (jsonString.isEmpty()) return emptyList()
        
        return try {
            json.decodeFromString<List<AppNotification>>(jsonString)
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * Saves all notifications.
     * Mirrors Swift's save(_:) for array.
     */
    fun save(notifications: List<AppNotification>) {
        val jsonString = json.encodeToString(notifications)
        keyValueStore.putString(ALL_NOTIFICATIONS_KEY, jsonString)
    }

    /**
     * Adds a notification.
     * Mirrors Swift's save(_:) for single notification.
     */
    fun save(notification: AppNotification) {
        val notifications = load().toMutableList()
        notifications.add(notification)
        save(notifications)
    }

    /**
     * Removes a notification.
     * Mirrors Swift's remove(_:).
     */
    fun remove(notification: AppNotification) {
        val notifications = load().toMutableList()
        notifications.removeAll { it.id == notification.id }
        save(notifications)
    }

    /**
     * Removes all notifications.
     * Mirrors Swift's removeAll().
     */
    fun removeAll() {
        save(emptyList())
    }

    /**
     * Checks if a notification exists.
     * Mirrors Swift's isInclude(_:).
     */
    fun isInclude(notificationId: Int): Boolean {
        return load().any { it.id == notificationId }
    }

    // MARK: - New Notifications

    /**
     * Loads new (unread) notifications.
     * Mirrors Swift's loadNew().
     */
    fun loadNew(): List<AppNotification> {
        val jsonString = keyValueStore.getString(NEW_NOTIFICATIONS_KEY)
        if (jsonString.isEmpty()) return emptyList()
        
        return try {
            json.decodeFromString<List<AppNotification>>(jsonString)
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * Saves new notifications.
     * Mirrors Swift's saveNew(_:) for array.
     */
    fun saveNew(notifications: List<AppNotification>) {
        val jsonString = json.encodeToString(notifications)
        keyValueStore.putString(NEW_NOTIFICATIONS_KEY, jsonString)
    }

    /**
     * Adds a new notification.
     * Mirrors Swift's saveNew(_:) for single notification.
     */
    fun saveNew(notification: AppNotification) {
        val notifications = loadNew().toMutableList()
        notifications.add(notification)
        saveNew(notifications)
    }

    /**
     * Removes all new notifications.
     * Mirrors Swift's removeNewAll().
     */
    fun removeNewAll() {
        saveNew(emptyList())
    }
}

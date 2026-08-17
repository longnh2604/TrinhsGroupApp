package com.trinhsgroup.shared.storage

/**
 * Platform-agnostic key-value storage interface.
 * This is an expect class that has platform-specific actual implementations:
 * - Android: SharedPreferences or DataStore
 * - iOS: NSUserDefaults
 *
 * Used for persisting favorites, notifications, and login state.
 */
expect class KeyValueStore {
    /**
     * Stores a string value.
     */
    fun putString(key: String, value: String)

    /**
     * Retrieves a string value.
     */
    fun getString(key: String, defaultValue: String = ""): String

    /**
     * Stores a boolean value.
     */
    fun putBoolean(key: String, value: Boolean)

    /**
     * Retrieves a boolean value.
     */
    fun getBoolean(key: String, defaultValue: Boolean = false): Boolean

    /**
     * Stores an integer value.
     */
    fun putInt(key: String, value: Int)

    /**
     * Retrieves an integer value.
     */
    fun getInt(key: String, defaultValue: Int = 0): Int

    /**
     * Removes a value by key.
     */
    fun remove(key: String)

    /**
     * Clears all stored values.
     */
    fun clear()

    /**
     * Checks if a key exists.
     */
    fun contains(key: String): Boolean
}

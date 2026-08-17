package com.trinhsgroup.shared.storage

import platform.Foundation.NSUserDefaults

/**
 * iOS implementation of KeyValueStore using NSUserDefaults.
 */
actual class KeyValueStore {
    private val defaults = NSUserDefaults.standardUserDefaults

    actual fun putString(key: String, value: String) {
        defaults.setObject(value, forKey = key)
        defaults.synchronize()
    }

    actual fun getString(key: String, defaultValue: String): String {
        return defaults.stringForKey(key) ?: defaultValue
    }

    actual fun putBoolean(key: String, value: Boolean) {
        defaults.setBool(value, forKey = key)
        defaults.synchronize()
    }

    actual fun getBoolean(key: String, defaultValue: Boolean): Boolean {
        return if (defaults.objectForKey(key) != null) {
            defaults.boolForKey(key)
        } else {
            defaultValue
        }
    }

    actual fun putInt(key: String, value: Int) {
        defaults.setInteger(value.toLong(), forKey = key)
        defaults.synchronize()
    }

    actual fun getInt(key: String, defaultValue: Int): Int {
        return if (defaults.objectForKey(key) != null) {
            defaults.integerForKey(key).toInt()
        } else {
            defaultValue
        }
    }

    actual fun remove(key: String) {
        defaults.removeObjectForKey(key)
        defaults.synchronize()
    }

    actual fun clear() {
        val dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key ->
            (key as? String)?.let { defaults.removeObjectForKey(it) }
        }
        defaults.synchronize()
    }

    actual fun contains(key: String): Boolean {
        return defaults.objectForKey(key) != null
    }
}

package com.trinhsgroup.shared.storage

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * Android implementation of KeyValueStore using SharedPreferences.
 *
 * Encrypted at rest, because this also holds the session JWT — the Android counterpart of
 * the iOS app keeping it in the Keychain rather than UserDefaults. If the keystore is
 * unavailable (some rooted or badly-provisioned devices throw), it falls back to plain
 * preferences so the app still runs.
 */
actual class KeyValueStore(context: Context) {
    private val prefs: SharedPreferences = try {
        EncryptedSharedPreferences.create(
            context,
            "trinhsgroup_prefs_secure",
            MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    } catch (e: Exception) {
        println("🔐 KeyValueStore: encrypted preferences unavailable (${e.message}), falling back")
        context.getSharedPreferences("trinhsgroup_prefs", Context.MODE_PRIVATE)
    }

    actual fun putString(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }

    actual fun getString(key: String, defaultValue: String): String {
        return prefs.getString(key, defaultValue) ?: defaultValue
    }

    actual fun putBoolean(key: String, value: Boolean) {
        prefs.edit().putBoolean(key, value).apply()
    }

    actual fun getBoolean(key: String, defaultValue: Boolean): Boolean {
        return prefs.getBoolean(key, defaultValue)
    }

    actual fun putInt(key: String, value: Int) {
        prefs.edit().putInt(key, value).apply()
    }

    actual fun getInt(key: String, defaultValue: Int): Int {
        return prefs.getInt(key, defaultValue)
    }

    actual fun remove(key: String) {
        prefs.edit().remove(key).apply()
    }

    actual fun clear() {
        prefs.edit().clear().apply()
    }

    actual fun contains(key: String): Boolean {
        return prefs.contains(key)
    }
}

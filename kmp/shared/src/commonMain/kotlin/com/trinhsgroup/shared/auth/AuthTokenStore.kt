package com.trinhsgroup.shared.auth

import com.trinhsgroup.shared.storage.KeyValueStore
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.datetime.Clock
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

/**
 * The signed-in user's JWT, which authorises every `/wp-json/trinh-app/v1` call.
 *
 * Mirrors Swift's AuthTokenStore (Utility/KeychainStore.swift). On Android the backing
 * KeyValueStore is encrypted at rest — see the androidMain implementation.
 */
class AuthTokenStore(private val store: KeyValueStore) {

    private val _sessionExpired = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    /** Emits when the server rejected the token, or when a stored token turns out to be stale. */
    val sessionExpired: SharedFlow<Unit> = _sessionExpired.asSharedFlow()

    val token: String?
        get() = store.getString(KEY_TOKEN, "").ifEmpty { null }

    fun save(token: String) {
        store.putString(KEY_TOKEN, token)
    }

    fun clear() {
        store.remove(KEY_TOKEN)
    }

    fun notifyExpired() {
        _sessionExpired.tryEmit(Unit)
    }

    /**
     * True when there is no token, or its `exp` claim is in the past.
     *
     * A token whose expiry cannot be read is treated as valid — same as iOS. The server is
     * the real gate; this only saves a round trip and stops the app showing a logged-in
     * shell it cannot fill.
     */
    fun isExpired(): Boolean {
        val jwt = token ?: return true
        val expiry = jwtExpirationEpochSeconds(jwt) ?: return false
        return expiry < Clock.System.now().epochSeconds
    }

    private companion object {
        const val KEY_TOKEN = "authJWTToken"
    }
}

/** Seconds since epoch from a JWT's `exp` claim, or null if it can't be read. */
@OptIn(ExperimentalEncodingApi::class)
internal fun jwtExpirationEpochSeconds(jwt: String): Long? {
    val segments = jwt.split(".")
    if (segments.size != 3) return null
    return try {
        val payload = Base64.UrlSafe.withPadding(Base64.PaddingOption.ABSENT_OPTIONAL)
            .decode(segments[1])
            .decodeToString()
        Json.parseToJsonElement(payload).jsonObject["exp"]?.jsonPrimitive?.longOrNull
    } catch (_: Exception) {
        null
    }
}

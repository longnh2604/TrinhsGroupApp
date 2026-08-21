package com.trinhskitchen.app.firebase

import com.google.firebase.messaging.FirebaseMessaging
import com.trinhsgroup.shared.auth.AuthTokenStore
import com.trinhsgroup.shared.service.AuthService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

/**
 * Binds this device's FCM token to the signed-in account, and unbinds it before the session
 * ends. Mirrors Swift's registerFCMTokenIfNeeded() / unregisterFCMToken().
 */
class PushTokens(
    private val authService: AuthService,
    private val tokenStore: AuthTokenStore
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /**
     * Registers in the background. Safe to call repeatedly — the server keys on the token, and
     * a failure is dropped because the next login registers again.
     */
    fun register() {
        if (tokenStore.token.isNullOrEmpty()) {
            println("📱 FCM register skipped — no JWT for the current session")
            return
        }
        scope.launch { authService.registerPushToken(deviceToken()) }
    }

    /**
     * Unbinds this device. Suspends because it has to reach the server while the JWT is still
     * in the store — the caller must not log out until it returns.
     *
     * Bounded, because logout waits on it: a slow network must not hold the customer on the
     * screen they just asked to leave. A missed unregister leaves a stale binding the server
     * drops on the next register.
     */
    suspend fun unregister() {
        if (tokenStore.token.isNullOrEmpty()) return
        withTimeoutOrNull(UNREGISTER_TIMEOUT_MS) { authService.unregisterPushToken(deviceToken()) }
            ?: println("📱 FCM unregister gave up after ${UNREGISTER_TIMEOUT_MS}ms")
    }

    private companion object {
        const val UNREGISTER_TIMEOUT_MS = 3_000L
    }

    private suspend fun deviceToken(): String = suspendCancellableCoroutine { continuation ->
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            continuation.resume(task.result?.takeIf { task.isSuccessful } ?: "")
        }
    }
}

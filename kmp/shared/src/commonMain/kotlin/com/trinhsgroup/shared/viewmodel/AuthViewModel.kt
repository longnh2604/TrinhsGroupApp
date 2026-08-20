package com.trinhsgroup.shared.viewmodel

import com.trinhsgroup.shared.auth.AuthTokenStore
import com.trinhsgroup.shared.model.User
import com.trinhsgroup.shared.model.UserAuth
import com.trinhsgroup.shared.service.AuthService
import com.trinhsgroup.shared.storage.KeyValueStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

/**
 * Authentication state for proper state management.
 * Mirrors the expected auth states:
 * - Loading: Checking stored session on app launch
 * - Authenticated: User is logged in with valid session
 * - Unauthenticated: User is not logged in or session expired
 */
sealed class AuthState {
    object Loading : AuthState()
    object Authenticated : AuthState()
    object Unauthenticated : AuthState()
}

/**
 * Shared ViewModel for authentication.
 * Mirrors Swift's AuthViewModel class.
 *
 * Note: On Android, wrap this in an AndroidX ViewModel.
 * On iOS, use this directly with lifecycle management.
 */
class AuthViewModel(
    private val service: AuthService,
    private val keyValueStore: KeyValueStore,
    private val tokenStore: AuthTokenStore
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Login state backed by KeyValueStore
    private val _isLogin = MutableStateFlow(keyValueStore.getBoolean(KEY_IS_LOGIN, false))
    val isLogin: StateFlow<Boolean> = _isLogin.asStateFlow()

    // Auth state for proper state management
    private val _authState = MutableStateFlow<AuthState>(AuthState.Loading)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    private val _user = MutableStateFlow(User.Empty)
    val user: StateFlow<User> = _user.asStateFlow()

    private val _authUser = MutableStateFlow<UserAuth?>(null)
    val authUser: StateFlow<UserAuth?> = _authUser.asStateFlow()

    // Form fields
    private val _username = MutableStateFlow("")
    val username: StateFlow<String> = _username.asStateFlow()

    private val _email = MutableStateFlow("")
    val email: StateFlow<String> = _email.asStateFlow()

    private val _password = MutableStateFlow("")
    val password: StateFlow<String> = _password.asStateFlow()

    private val _showLoading = MutableStateFlow(false)
    val showLoading: StateFlow<Boolean> = _showLoading.asStateFlow()

    private val _message = MutableStateFlow("")
    val message: StateFlow<String> = _message.asStateFlow()

    private val _showEditProfile = MutableStateFlow(false)
    val showEditProfile: StateFlow<Boolean> = _showEditProfile.asStateFlow()

    private val _showEditAddress = MutableStateFlow(false)
    val showEditAddress: StateFlow<Boolean> = _showEditAddress.asStateFlow()

    private val _isUpdatedUser = MutableStateFlow(false)
    val isUpdatedUser: StateFlow<Boolean> = _isUpdatedUser.asStateFlow()

    private val _isCreatedUser = MutableStateFlow(false)
    val isCreatedUser: StateFlow<Boolean> = _isCreatedUser.asStateFlow()

    private val _isShowForgot = MutableStateFlow(false)
    val isShowForgot: StateFlow<Boolean> = _isShowForgot.asStateFlow()

    /** True once a reset email has gone out for the address just entered. */
    private val _isPasswordReset = MutableStateFlow(false)
    val isPasswordReset: StateFlow<Boolean> = _isPasswordReset.asStateFlow()

    /** Set when a stored session turned out to be over, so the UI can say so once. */
    private val _isTokenExpired = MutableStateFlow(false)
    val isTokenExpired: StateFlow<Boolean> = _isTokenExpired.asStateFlow()

    init {
        bindingData()
    }

    private fun bindingData() {
        // A rejected token anywhere in the app ends the session here, once.
        tokenStore.sessionExpired.onEach {
            if (_isLogin.value) {
                logout()
                _isTokenExpired.value = true
            }
        }.launchIn(scope)

        service.isLoading.onEach { isLoading ->
            _showLoading.value = isLoading
        }.launchIn(scope)

        service.error.onEach { error ->
            _message.value = error
        }.launchIn(scope)

        service.isLoggedIn.onEach { isLoggedIn ->
            _isLogin.value = isLoggedIn
            keyValueStore.putBoolean(KEY_IS_LOGIN, isLoggedIn)
            if (isLoggedIn && _user.value.id > 0) {
                _authState.value = AuthState.Authenticated
            }
        }.launchIn(scope)

        service.isCreated.onEach { isCreated ->
            _isCreatedUser.value = isCreated
        }.launchIn(scope)

        service.isUpdated.onEach { isUpdated ->
            _isUpdatedUser.value = isUpdated
            // Note: In iOS, there's a delay to reset this after ALERT_MESSAGE_DURATION
            // That timing logic should be handled by the UI layer
        }.launchIn(scope)

        service.isReset.onEach { isReset ->
            _isShowForgot.value = !isReset
            _isPasswordReset.value = isReset
        }.launchIn(scope)

        service.authUser.onEach { authUser ->
            _authUser.value = authUser
            // Kept only to prefill the login field; the session itself is the stored JWT.
            if (authUser != null) {
                keyValueStore.putString(KEY_USER_EMAIL, authUser.email)

                // Automatically fetch user info after successful login
                // This gets the WooCommerce customer data including user.id
                println("🔐 AuthViewModel: Fetching the signed-in customer")
                scope.launch {
                    service.fetchingUserInfo()
                }
            }
        }.launchIn(scope)

        service.user.onEach { user ->
            _user.value = user
            // Update auth state when user is loaded
            if (user.id > 0) {
                _authState.value = AuthState.Authenticated
                println("🔐 AuthViewModel: User loaded, id=${user.id}, authState=Authenticated")
            }
        }.launchIn(scope)
    }

    // Form field setters
    fun setUsername(value: String) {
        _username.value = value
    }

    fun setEmail(value: String) {
        _email.value = value
    }

    fun setPassword(value: String) {
        _password.value = value
    }

    fun setShowEditProfile(value: Boolean) {
        _showEditProfile.value = value
    }

    fun setShowEditAddress(value: Boolean) {
        _showEditAddress.value = value
    }

    /**
     * Creates a new user account.
     * Validates fields before calling service.
     */
    fun createUser() {
        if (_username.value.isEmpty() || _email.value.isEmpty() || _password.value.isEmpty()) {
            _message.value = "Please fill all data"
            return
        }
        scope.launch {
            service.createUser(
                username = _username.value,
                firstName = "",
                lastName = "",
                password = _password.value,
                email = _email.value
            )
        }
    }

    /**
     * Authenticates the user.
     * Validates fields before calling service.
     */
    fun onAuthUser() {
        if (_email.value.isEmpty() || _password.value.isEmpty()) {
            _message.value = "Please fill all data"
            return
        }
        scope.launch {
            service.onAuthUser(
                email = _email.value,
                password = _password.value
            )
        }
    }

    /**
     * Updates user information.
     */
    fun onUpdateUser(user: User) {
        scope.launch {
            service.updateUser(user = user, password = _password.value)
        }
    }

    /**
     * Clears the "profile saved" flag before a screen starts watching for it.
     */
    fun clearUpdatedUser() {
        service.clearUpdated()
    }

    /**
     * Clears the "reset email sent" flag before a screen starts watching for it.
     */
    fun clearPasswordReset() {
        service.clearReset()
    }

    /**
     * Ends the session when the stored token has already expired, so an order is not sent
     * on a token the server will reject.
     *
     * Mirrors the isTokenExpiredCheck() guard on iOS's submit button.
     *
     * @return true when the session was ended and the caller should stop
     */
    fun endSessionIfTokenExpired(): Boolean {
        if (tokenStore.token != null && !tokenStore.isExpired()) return false

        println("🔐 AuthViewModel: Token expired at submit, ending session")
        logout()
        _isTokenExpired.value = true
        return true
    }

    /**
     * Checks if user has filled billing info.
     * Currently always returns true (commented out in iOS).
     */
    fun checkUserUpdatedBillInfo(): Boolean {
        // In iOS, this check is commented out
        // if (!user.billing.checkFilledData()) {
        //     message = "Please fill your billing info before start to create order, thank you."
        //     return false
        // }
        return true
    }

    /**
     * Fetches user info based on authenticated user's email.
     */
    fun onGetUser() {
        scope.launch {
            service.fetchingUserInfo()
        }
    }

    /**
     * Restores the session on app launch.
     *
     * The stored JWT is what a session *is* — an email in preferences proves nothing now
     * that every customer route is authorised by the token. An expired token is cleared
     * here rather than left for the first request to trip over.
     */
    fun restoreSession() {
        if (tokenStore.token == null) {
            _authState.value = AuthState.Unauthenticated
            println("🔐 AuthViewModel.restoreSession: No stored session")
            return
        }

        if (tokenStore.isExpired()) {
            println("🔐 AuthViewModel.restoreSession: Token expired, clearing session")
            logout()
            _isTokenExpired.value = true
            return
        }

        scope.launch {
            println("🔐 AuthViewModel.restoreSession: Token valid, loading customer...")
            service.fetchingUserInfo()

            // Read the service's own value, not this class's mirror of it: the mirror is
            // filled by a separate collector that has not necessarily run yet, and treating
            // that gap as a failed fetch signed the customer out of a perfectly good session.
            if (service.user.value.id > 0) {
                println("🔐 AuthViewModel.restoreSession: User restored, id=${service.user.value.id}")
                service.markLoggedIn()
                _authState.value = AuthState.Authenticated
            } else {
                println("🔐 AuthViewModel.restoreSession: User fetch failed, clearing session")
                logout()
            }
        }
    }

    /**
     * Initiates password reset.
     */
    fun onForgotPassword(email: String) {
        scope.launch {
            service.onForgotPassword(email = email)
        }
    }

    /**
     * Clears the message state.
     */
    fun clearMessage() {
        _message.value = ""
    }

    /**
     * Logs out the user.
     */
    /**
     * Permanently deletes the signed-in account, then clears the local session.
     * Mirrors Swift's onDeleteAccount().
     *
     * @param onResult called with false when the server refused, so the caller can say so
     *                 rather than navigating away from an account that still exists
     */
    fun onDeleteAccount(onResult: (Boolean) -> Unit) {
        if (_user.value.id <= 0) {
            _message.value = "Invalid user account"
            onResult(false)
            return
        }

        scope.launch {
            val deleted = service.deleteAccount()
            if (deleted) logout()
            onResult(deleted)
        }
    }

    fun logout() {
        tokenStore.clear()
        _isLogin.value = false
        _authState.value = AuthState.Unauthenticated
        keyValueStore.putBoolean(KEY_IS_LOGIN, false)
        keyValueStore.putString(KEY_USER_EMAIL, "")
        _user.value = User.Empty
        _authUser.value = null
        println("🔐 AuthViewModel.logout: Session cleared, authState=Unauthenticated")
    }

    companion object {
        private const val KEY_IS_LOGIN = "isLogin"
        private const val KEY_USER_EMAIL = "userEmail"
    }
}

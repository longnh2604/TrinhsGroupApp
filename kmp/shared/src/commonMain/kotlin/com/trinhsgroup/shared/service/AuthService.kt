package com.trinhsgroup.shared.service

import com.trinhsgroup.shared.auth.AuthTokenStore
import com.trinhsgroup.shared.model.RegistrationResponse
import com.trinhsgroup.shared.model.User
import com.trinhsgroup.shared.model.UserAuth
import com.trinhsgroup.shared.model.WooErrorResponse
import com.trinhsgroup.shared.network.AppError
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import com.trinhsgroup.shared.network.HttpMethod
import com.trinhsgroup.shared.network.WooCommerceApi
import com.trinhsgroup.shared.network.WooCommerceEndpoint
import com.trinhsgroup.shared.network.request
import com.trinhsgroup.shared.network.requestBasicAuth
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Authentication service for user login, registration, and password reset.
 * Mirrors Swift's AuthServices class.
 */
class AuthService(
    private val api: WooCommerceApi = WooCommerceApi(),
    private val tokenStore: AuthTokenStore
) {
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow("")
    val error: StateFlow<String> = _error.asStateFlow()

    private val _authUser = MutableStateFlow<UserAuth?>(null)
    val authUser: StateFlow<UserAuth?> = _authUser.asStateFlow()

    private val _user = MutableStateFlow(User.Empty)
    val user: StateFlow<User> = _user.asStateFlow()

    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn: StateFlow<Boolean> = _isLoggedIn.asStateFlow()

    private val _isCreated = MutableStateFlow(false)
    val isCreated: StateFlow<Boolean> = _isCreated.asStateFlow()

    private val _isUpdated = MutableStateFlow(false)
    val isUpdated: StateFlow<Boolean> = _isUpdated.asStateFlow()

    private val _isReset = MutableStateFlow(false)
    val isReset: StateFlow<Boolean> = _isReset.asStateFlow()

    /**
     * Creates a new user/customer account.
     * Mirrors Swift's createUser().
     *
     * Signup goes through the server-side `trinh-app/v1/register` route, which creates the
     * customer with WordPress's own APIs. That is why the app can ship a read-only consumer
     * key — account creation is the only write that predates having a JWT.
     *
     * @param username The username
     * @param firstName User's first name
     * @param lastName User's last name
     * @param password Account password
     * @param email User's email address
     */
    suspend fun createUser(
        username: String,
        firstName: String,
        lastName: String,
        password: String,
        email: String
    ) {
        _isLoading.value = true
        _error.value = ""

        try {
            val body = buildJsonObject {
                put("email", email)
                put("username", username)
                put("password", password)
                put("name", listOf(firstName, lastName).filter { it.isNotEmpty() }.joinToString(" "))
            }

            val registration: RegistrationResponse = api.request(
                endpoint = WooCommerceEndpoint.Register,
                method = HttpMethod.POST,
                body = body
            )
            println("✅ AuthService: Registered customer ${registration.id} <${registration.email}>")
            _isCreated.value = true
        } catch (e: WooErrorResponse) {
            _error.value = e.message
        } catch (e: Exception) {
            _error.value = e.message ?: "Unknown error"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Authenticates a user via JWT endpoint.
     * Mirrors Swift's onAuthUser().
     *
     * @param email User's email/username
     * @param password User's password
     */
    suspend fun onAuthUser(email: String, password: String) {
        _isLoading.value = true
        _error.value = ""

        println("🔐 AuthService: Starting authentication for $email")
        
        try {
            val userAuth: UserAuth = api.requestBasicAuth(
                endpoint = WooCommerceEndpoint.Authenticate,
                email = email,
                password = password
            )
            println("✅ AuthService: Authentication successful for ${userAuth.email}")
            // Every customer-scoped route reads this token, so it is stored before anything
            // downstream reacts to isLoggedIn and starts fetching.
            tokenStore.save(userAuth.token)
            _authUser.value = userAuth
            _isLoggedIn.value = true
        } catch (e: WooErrorResponse) {
            // JWT plugin returns WooErrorResponse format
            println("❌ AuthService: WooErrorResponse - ${e.code}: ${e.message}")
            _error.value = e.message
        } catch (e: AppError) {
            println("❌ AuthService: AppError - ${e.statusCode}: ${e.message}")
            _error.value = e.message ?: "Authentication failed (${e.statusCode})"
        } catch (e: Exception) {
            println("❌ AuthService: Exception - ${e::class.simpleName}: ${e.message}")
            _error.value = e.message ?: "Authentication failed"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Sends a password reset email.
     * Mirrors Swift's onForgotPassword().
     *
     * @param email User's email address
     */
    suspend fun onForgotPassword(email: String) {
        _isLoading.value = true
        _error.value = ""

        try {
            api.sendPasswordReset(
                endpoint = WooCommerceEndpoint.ForgotPassword,
                email = email
            )
            _isReset.value = true
        } catch (e: Exception) {
            _error.value = e.message ?: "Password reset failed"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Updates the signed-in customer.
     * Mirrors Swift's updateUser().
     *
     * @param user The user to update
     * @param password New password, or empty to leave it unchanged
     */
    suspend fun updateUser(user: User, password: String) {
        if (user.id <= 0) {
            _error.value = "Invalid user account"
            return
        }

        _isLoading.value = true
        _error.value = ""

        try {
            val body = buildJsonObject {
                put("email", user.email)
                put("first_name", user.firstName)
                put("last_name", user.lastName)
                put("billing", buildJsonObject {
                    put("first_name", user.billing.firstName)
                    put("last_name", user.billing.lastName)
                    put("company", user.billing.company)
                    put("country", user.billing.country)
                    put("address_1", user.billing.address1)
                    put("city", user.billing.city)
                    put("postcode", user.billing.postcode)
                    put("state", user.billing.state)
                    put("email", user.billing.email)
                    put("phone", user.billing.phone)
                })
                put("shipping", buildJsonObject {
                    put("first_name", user.shipping.firstName)
                    put("last_name", user.shipping.lastName)
                    put("company", user.shipping.company)
                    put("country", user.shipping.country)
                    put("address_1", user.shipping.address1)
                    put("city", user.shipping.city)
                    put("postcode", user.shipping.postcode)
                    put("state", user.shipping.state)
                    put("phone", user.shipping.phone)
                })
                if (password.isNotEmpty()) {
                    put("password", password)
                }
            }

            val updated: User = api.request(
                endpoint = WooCommerceEndpoint.Me,
                method = HttpMethod.PUT,
                body = body
            )
            _user.value = updated
            _isUpdated.value = true
        } catch (e: WooErrorResponse) {
            _error.value = e.message
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to update profile"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Loads the signed-in customer.
     * Mirrors Swift's fetchingUserInfo().
     *
     * The account is identified by the JWT, so no email lookup is sent — the previous
     * `?email=` query could read any customer in the store.
     */
    suspend fun fetchingUserInfo() {
        _isLoading.value = true
        _error.value = ""

        try {
            val user: User = api.request(
                endpoint = WooCommerceEndpoint.Me,
                method = HttpMethod.GET
            )
            _user.value = user
        } catch (e: Exception) {
            _error.value = e.message ?: "Failed to fetch user info"
        } finally {
            _isLoading.value = false
        }
    }

    /**
     * Clears the error state.
     */
    fun clearError() {
        _error.value = ""
    }

    /**
     * Resets all state flags.
     */
    fun resetState() {
        _isCreated.value = false
        _isUpdated.value = false
        _isReset.value = false
        _isLoggedIn.value = false
        _error.value = ""
    }
}

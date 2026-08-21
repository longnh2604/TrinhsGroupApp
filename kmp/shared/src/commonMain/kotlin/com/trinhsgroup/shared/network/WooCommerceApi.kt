package com.trinhsgroup.shared.network

import com.trinhsgroup.shared.auth.AuthTokenStore
import com.trinhsgroup.shared.model.RedeemErrorResponse
import com.trinhsgroup.shared.model.WooErrorResponse
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logging
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.timeout
import io.ktor.client.request.HttpRequestBuilder
import io.ktor.client.request.forms.MultiPartFormDataContent
import io.ktor.client.request.forms.formData
import io.ktor.client.request.delete
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.request.parameter
import io.ktor.client.request.post
import io.ktor.client.request.put
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.content.TextContent
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.JsonElement
import kotlinx.datetime.Clock
import kotlinx.serialization.json.Json
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

/**
 * API client for the store.
 * Mirrors Swift's WooCommerceAPI struct in Utility/WooCommerceOAuth.swift.
 *
 * Authorisation is decided per endpoint, not per call site: routes with
 * [WooCommerceEndpoint.requiresJwt] carry the signed-in user's Bearer token, everything
 * else carries the read-only consumer key. That key can only read the public catalog, so
 * shipping it inside the app grants nobody anything the website doesn't already show.
 */
class WooCommerceApi(
    private val storeUrl: String = DEFAULT_STORE_URL,
    private val consumerKey: String = "",
    private val consumerSecret: String = "",
    private val tokenStore: AuthTokenStore? = null
) {
    internal val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
        coerceInputValues = true
    }

    internal val client: HttpClient by lazy {
        HttpClient(createHttpClientEngine()) {
            install(ContentNegotiation) {
                json(json)
            }
            install(Logging) {
                level = LogLevel.INFO
            }
            // No global timeouts — only the avatar upload asks for one, and the engine's own
            // defaults are what every other call has always run with.
            install(HttpTimeout)
            defaultRequest {
                header(HttpHeaders.UserAgent, "TrinhsGroup/1.0 (Android)")
            }
        }
    }

    /**
     * Returns current timestamp in milliseconds for cache busting.
     */
    internal fun currentTimeMillis(): Long = Clock.System.now().toEpochMilliseconds()

    /**
     * Builds a full URL for the given endpoint.
     */
    internal fun buildUrl(endpoint: WooCommerceEndpoint): String = "$storeUrl${endpoint.urlPath()}"

    /**
     * Adds the Authorization header the endpoint calls for — or none, for the public
     * `trinh-app` routes, which answer 401 if a consumer key is sent to them.
     *
     * Refusing a JWT route without a token — rather than sending it bare and reading the
     * 401 — keeps a signed-out app from advertising the attempt, and gives the caller the
     * same "session expired" error either way.
     */
    @OptIn(ExperimentalEncodingApi::class)
    internal fun HttpRequestBuilder.applyAuthorization(endpoint: WooCommerceEndpoint) {
        when (endpoint.auth) {
            EndpointAuth.NONE -> return

            EndpointAuth.CONSUMER_KEY -> {
                if (consumerKey.isNotEmpty()) {
                    val credentials = Base64.encode("$consumerKey:$consumerSecret".encodeToByteArray())
                    header(HttpHeaders.Authorization, "Basic $credentials")
                }
            }

            EndpointAuth.JWT -> {
                val token = tokenStore?.token
                if (token.isNullOrEmpty()) {
                    println("🔐 Refusing ${endpoint.urlPath()} — no JWT for the current session")
                    tokenStore?.notifyExpired()
                    throw AppError(statusCode = 401, message = SESSION_EXPIRED_MESSAGE)
                }
                header(HttpHeaders.Authorization, "Bearer $token")
            }
        }
    }

    /**
     * A rejected JWT means the session is gone. Tells [AuthTokenStore] so the UI can bounce
     * the user to login exactly once, whichever call happened to notice first.
     */
    fun checkAuthFailure(endpoint: WooCommerceEndpoint, statusCode: Int) {
        if (!endpoint.requiresJwt) return
        if (statusCode != 401 && statusCode != 403) return
        println("🔐 $statusCode on ${endpoint.urlPath()} — session no longer valid")
        tokenStore?.notifyExpired()
        throw AppError(statusCode = statusCode, message = SESSION_EXPIRED_MESSAGE)
    }

    suspend fun doGet(
        endpoint: WooCommerceEndpoint,
        params: Map<String, String> = emptyMap()
    ): HttpResponse = client.get(buildUrl(endpoint)) {
        applyAuthorization(endpoint)
        parameter("_", currentTimeMillis())
        params.forEach { (key, value) -> parameter(key, value) }
        header(HttpHeaders.CacheControl, "no-cache")
        header("Pragma", "no-cache")
    }

    suspend fun doPost(
        endpoint: WooCommerceEndpoint,
        params: Map<String, String> = emptyMap(),
        body: Any? = null
    ): HttpResponse {
        val url = buildUrl(endpoint)
        println("🌐 API: POST $url")
        body?.let { println("🌐 API: Body = $it") }

        return client.post(url) {
            applyAuthorization(endpoint)
            params.forEach { (key, value) -> parameter(key, value) }
            header(HttpHeaders.CacheControl, "no-cache")
            header("Pragma", "no-cache")
            body?.let { setBody(jsonRequestBody(it)) }
        }
    }

    suspend fun doPut(
        endpoint: WooCommerceEndpoint,
        params: Map<String, String> = emptyMap(),
        body: Any? = null
    ): HttpResponse = client.put(buildUrl(endpoint)) {
        applyAuthorization(endpoint)
        params.forEach { (key, value) -> parameter(key, value) }
        header(HttpHeaders.CacheControl, "no-cache")
        header("Pragma", "no-cache")
        body?.let { setBody(jsonRequestBody(it)) }
    }

    suspend fun doDelete(
        endpoint: WooCommerceEndpoint,
        params: Map<String, String> = emptyMap()
    ): HttpResponse = client.delete(buildUrl(endpoint)) {
        applyAuthorization(endpoint)
        params.forEach { (key, value) -> parameter(key, value) }
        header(HttpHeaders.CacheControl, "no-cache")
        header("Pragma", "no-cache")
    }

    /**
     * Uploads one file as multipart form data. Mirrors Swift's uploadCustomerAvatar().
     *
     * A longer timeout than the JSON calls get: a photo off a phone camera is measured in
     * megabytes, and the default read timeout cuts an upload that was going to succeed.
     */
    suspend fun doMultipartUpload(
        endpoint: WooCommerceEndpoint,
        fieldName: String,
        fileName: String,
        mimeType: String,
        bytes: ByteArray
    ): HttpResponse {
        println("🌐 API: POST ${buildUrl(endpoint)} (multipart, ${bytes.size} bytes)")
        return client.post(buildUrl(endpoint)) {
            applyAuthorization(endpoint)
            timeout { requestTimeoutMillis = UPLOAD_TIMEOUT_MS }
            setBody(
                MultiPartFormDataContent(
                    formData {
                        append(
                            key = fieldName,
                            value = bytes,
                            headers = Headers.build {
                                append(HttpHeaders.ContentType, mimeType)
                                append(
                                    HttpHeaders.ContentDisposition,
                                    "filename=\"$fileName\""
                                )
                            }
                        )
                    }
                )
            )
        }
    }

    /**
     * Submits form data without authentication.
     * Used by login and password reset, which are how a session starts.
     */
    suspend fun doFormSubmit(
        endpoint: WooCommerceEndpoint,
        formData: Map<String, String>
    ): HttpResponse {
        val body = formData.entries.joinToString("&") { "${it.key}=${it.value}" }
        println("🌐 doFormSubmit: URL = ${buildUrl(endpoint)}")
        return client.post(buildUrl(endpoint)) {
            contentType(ContentType.Application.FormUrlEncoded)
            setBody(body)
        }
    }

    /**
     * Sends a password reset request.
     * Mirrors Swift's sendPasswordReset() function.
     */
    suspend fun sendPasswordReset(
        endpoint: WooCommerceEndpoint,
        email: String
    ): Boolean {
        doFormSubmit(endpoint, mapOf("user_login" to email))
        // Swift always returns success if there was no network error
        return true
    }

    /**
     * Attempts to parse error responses in order of specificity and throws.
     * Returns Nothing - always throws an exception.
     */
    fun throwParsedError(bodyText: String, statusCode: Int): Nothing {
        // Try RedeemErrorResponse first (for /bu/v1/redeem endpoint)
        try {
            val redeemError = json.decodeFromString<RedeemErrorResponse>(bodyText)
            throw AppError(statusCode = statusCode, message = redeemError.error)
        } catch (e: AppError) {
            throw e
        } catch (_: Exception) { }

        // Try WooErrorResponse
        try {
            val wooError = json.decodeFromString<WooErrorResponse>(bodyText)
            throw wooError
        } catch (e: WooErrorResponse) {
            throw e
        } catch (_: Exception) { }

        // Fall back to generic error
        throw AppError(code = statusCode)
    }

    fun close() {
        client.close()
    }

    companion object {
        const val DEFAULT_STORE_URL = "https://trinhsgroup.com.au"
        const val SESSION_EXPIRED_MESSAGE = "Your session has expired. Please log in again."
        const val UPLOAD_TIMEOUT_MS = 120_000L
    }
}

/**
 * Extension functions for typed request/response handling.
 * These are inline functions outside the class to avoid visibility issues.
 */

/**
 * Makes a request, authorised according to the endpoint, and returns a typed response.
 */
suspend inline fun <reified T> WooCommerceApi.request(
    endpoint: WooCommerceEndpoint,
    method: HttpMethod = HttpMethod.GET,
    params: Map<String, String> = emptyMap(),
    body: Any? = null
): T {
    val response = when (method) {
        HttpMethod.GET -> doGet(endpoint, params)
        HttpMethod.POST -> doPost(endpoint, params, body)
        HttpMethod.PUT -> doPut(endpoint, params, body)
        HttpMethod.DELETE -> doDelete(endpoint, params)
    }
    checkAuthFailure(endpoint, response.status.value)
    return handleResponse(response)
}

/**
 * Uploads one file and returns the typed response.
 */
suspend inline fun <reified T> WooCommerceApi.upload(
    endpoint: WooCommerceEndpoint,
    fieldName: String,
    fileName: String,
    mimeType: String,
    bytes: ByteArray
): T {
    val response = doMultipartUpload(endpoint, fieldName, fileName, mimeType, bytes)
    checkAuthFailure(endpoint, response.status.value)
    return handleResponse(response)
}

/**
 * Makes a login request with form-encoded credentials.
 */
suspend inline fun <reified T> WooCommerceApi.requestBasicAuth(
    endpoint: WooCommerceEndpoint,
    email: String,
    password: String
): T {
    println("🌐 API: Sending auth request to ${endpoint.urlPath()}")
    val response = doFormSubmit(endpoint, mapOf("username" to email, "password" to password))
    println("📥 API: Response status = ${response.status}")
    return handleResponse(response)
}

/**
 * Handles HTTP response, parsing errors appropriately.
 */
suspend inline fun <reified T> WooCommerceApi.handleResponse(response: HttpResponse): T {
    if (response.status.isSuccess()) {
        return try {
            response.body<T>()
        } catch (e: Exception) {
            val bodyText = response.bodyAsText()
            println("⚠️ API: Parsing error, body = $bodyText")
            throwParsedError(bodyText, response.status.value)
        }
    } else {
        val bodyText = response.bodyAsText()
        println("❌ API: Error response (${response.status.value}), body = $bodyText")
        throwParsedError(bodyText, response.status.value)
    }
}

/**
 * Turns a request body into something Ktor can put on the wire.
 *
 * Every service builds its payload with `buildJsonObject`, and those arrive here typed as
 * `Any`, so content negotiation resolves a serializer from the runtime class and fails on
 * kotlinx's internal `JsonLiteral`. A JSON tree already knows how to print itself, so it
 * goes out as text and skips negotiation entirely; anything else is left alone.
 */
fun jsonRequestBody(body: Any): Any = when (body) {
    is JsonElement -> TextContent(body.toString(), ContentType.Application.Json)
    else -> body
}

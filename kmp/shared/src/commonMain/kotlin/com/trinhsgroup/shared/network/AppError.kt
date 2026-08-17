package com.trinhsgroup.shared.network

/**
 * Error codes for network and API errors.
 * Mirrors Swift's ErrorCode enum in NetworkAdapter.swift.
 */
enum class ErrorCode(val code: Int, val message: String) {
    NONE(-1, ""),
    UNKNOWN(10000, "Error. Please try again!"),
    CONNECTION(9999, "No internet connection!"),
    EXPIRED_TOKEN(401, ""),
    NOT_MODIFIED(304, "Not modified"),
    USE_PROXY(305, "Use Proxy"),
    BAD_REQUEST(400, "Bad Request"),
    FORBIDDEN(403, "Forbidden"),
    NOT_FOUND(404, "Not Found"),
    METHOD_NOT_ALLOWED(405, "Method Not Allowed"),
    REQUEST_TIMEOUT(408, "Request Timeout"),
    INTERNAL_SERVER_ERROR(500, "Internal Server Error"),
    SERVICE_UNAVAILABLE(503, "Service Unavailable"),
    GATEWAY_TIMEOUT(504, "Gateway Timeout");

    companion object {
        /**
         * Returns the ErrorCode for a given HTTP status code.
         * Returns UNKNOWN if no matching code is found.
         */
        fun fromCode(code: Int): ErrorCode {
            return entries.find { it.code == code } ?: UNKNOWN
        }
    }
}

/**
 * Application error wrapper.
 * Mirrors Swift's AppError struct in NetworkAdapter.swift.
 */
data class AppError(
    val statusCode: Int = 0,
    override val message: String = ""
) : Exception(message) {

    constructor(errorCode: ErrorCode) : this(
        statusCode = errorCode.code,
        message = errorCode.message
    )

    constructor(code: Int) : this(
        statusCode = code,
        message = ErrorCode.fromCode(code).message
    )

    companion object {
        val unknown = AppError(ErrorCode.UNKNOWN)
        val connection = AppError(ErrorCode.CONNECTION)
    }
}

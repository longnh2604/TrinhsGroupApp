package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

/**
 * WooCommerce error response wrapper.
 * Mirrors Swift's WooErrorResponse struct.
 *
 * Extends Exception so it can be thrown directly.
 */
@Serializable
data class WooErrorResponse(
    val code: String,
    override val message: String,
    val data: WooErrorData? = null
) : Exception(message)

/**
 * Additional error data from WooCommerce API.
 * Mirrors Swift's WooErrorData struct.
 */
@Serializable
data class WooErrorData(
    val status: Int? = null
)

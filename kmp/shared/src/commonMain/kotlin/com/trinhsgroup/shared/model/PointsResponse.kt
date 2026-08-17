package com.trinhsgroup.shared.model

import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonPrimitive

/**
 * Represents a points response from the myCred API.
 * Mirrors the Swift PointsResponse struct in PointsResponse.swift.
 */
@Serializable
data class PointsResponse(
    @SerialName("user_id") val userId: Int,
    val type: String,
    val balance: Double
)

/**
 * Represents a response from redeeming points.
 * Mirrors the Swift RedeemResponse struct in PointsResponse.swift.
 */
@Serializable
data class RedeemResponse(
    @SerialName("coupon_code") val couponCode: String,
    val amount: Double,
    val currency: String,
    @SerialName("expires_at") val expiresAt: String,
    @SerialName("points_used") val pointsUsed: Int,
    val balance: Double
) {
    /**
     * Parse expiration date from ISO-8601 string.
     */
    val expirationDate: Instant?
        get() = parseIso8601Date(expiresAt)
}

/**
 * Represents an error response from redeeming points.
 * Mirrors the Swift RedeemErrorResponse struct in PointsResponse.swift.
 */
@Serializable
data class RedeemErrorResponse(
    val error: String,
    val balance: Double? = null
)

/**
 * Parses an ISO-8601 date string to Instant.
 * Handles both with and without fractional seconds.
 */
internal fun parseIso8601Date(dateString: String): Instant? {
    if (dateString.isEmpty()) return null
    return try {
        Instant.parse(dateString)
    } catch (e: Exception) {
        // Try without fractional seconds
        try {
            // Handle format like "2024-01-15T12:00:00"
            val normalized = if (dateString.endsWith("Z")) dateString
            else if (dateString.contains("+") || dateString.count { it == '-' } > 2) dateString
            else "${dateString}Z"
            Instant.parse(normalized)
        } catch (e2: Exception) {
            null
        }
    }
}

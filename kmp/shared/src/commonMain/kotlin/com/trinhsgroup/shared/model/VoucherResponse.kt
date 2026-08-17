package com.trinhsgroup.shared.model

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a voucher from the API.
 * Mirrors the Swift VoucherResponse struct in PointsResponse.swift.
 */
@Serializable
data class VoucherResponse(
    val id: Int,
    val code: String,
    val amount: Double,
    val currency: String,
    @SerialName("expires_at") val expiresAt: String? = null,
    @SerialName("usage_count") val usageCount: Int,
    @SerialName("usage_limit") val usageLimit: Int,
    val status: String
) {
    /**
     * Parse expiration date from ISO-8601 string.
     */
    val expirationDate: Instant?
        get() = expiresAt?.let { parseIso8601Date(it) }

    /**
     * Check if voucher is expired.
     * Mirrors Swift's isExpired computed property.
     */
    val isExpired: Boolean
        get() {
            val expDate = expirationDate ?: return false
            return expDate < Clock.System.now()
        }

    /**
     * Formatted expiry date string.
     * Returns a medium-style date string or "No expiry" if no expiration.
     */
    val formattedExpiryDate: String
        get() {
            val expDate = expirationDate ?: return "No expiry"
            val localDate = expDate.toLocalDateTime(TimeZone.currentSystemDefault())
            return "${localDate.monthNumber}/${localDate.dayOfMonth}/${localDate.year}"
        }
}

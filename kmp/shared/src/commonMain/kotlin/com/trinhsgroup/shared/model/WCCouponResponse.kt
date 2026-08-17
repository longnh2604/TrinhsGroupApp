package com.trinhsgroup.shared.model

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull

/**
 * Represents a WooCommerce coupon response.
 * Mirrors the Swift WCCouponResponse struct in PointsResponse.swift.
 */
@Serializable
data class WCCouponResponse(
    val id: Int,
    val code: String,
    val amount: String, // WC returns amount as string
    @SerialName("discount_type") val discountType: String,
    val description: String,
    @SerialName("date_expires") val dateExpires: String? = null,
    @SerialName("date_expires_gmt") val dateExpiresGmt: String? = null,
    @SerialName("usage_count") val usageCount: Int,
    @SerialName("usage_limit") val usageLimit: Int? = null,
    @SerialName("usage_limit_per_user") val usageLimitPerUser: Int? = null,
    @SerialName("individual_use") val individualUse: Boolean,
    @SerialName("minimum_amount") val minimumAmount: String,
    @SerialName("maximum_amount") val maximumAmount: String,
    @SerialName("email_restrictions") val emailRestrictions: List<String>,
    @SerialName("used_by") @Serializable(with = UsedBySerializer::class)
    val usedBy: List<String>
) {
    /**
     * Get amount as Double.
     */
    val amountValue: Double
        get() = amount.toDoubleOrNull() ?: 0.0

    /**
     * Parse expiration date from ISO-8601 or simple date string.
     * Mirrors Swift's expirationDate computed property.
     */
    val expirationDate: Instant?
        get() {
            val dateStr = dateExpires
            if (dateStr.isNullOrEmpty()) return null

            // Try ISO-8601 with fractional seconds
            parseIso8601Date(dateStr)?.let { return it }

            // Try simple date format "yyyy-MM-dd'T'HH:mm:ss"
            return try {
                val normalized = if (dateStr.endsWith("Z")) dateStr
                else "${dateStr}Z"
                Instant.parse(normalized)
            } catch (e: Exception) {
                null
            }
        }

    /**
     * Check if coupon is expired.
     * Mirrors Swift's isExpired computed property.
     */
    val isExpired: Boolean
        get() {
            val expDate = expirationDate ?: return false
            return expDate < Clock.System.now()
        }

    /**
     * Check if coupon is still valid (not expired, not fully used).
     * Mirrors Swift's isValid computed property.
     */
    val isValid: Boolean
        get() {
            // Check expiration
            if (isExpired) return false
            // Check usage limit
            val limit = usageLimit
            if (limit != null && limit > 0 && usageCount >= limit) {
                return false
            }
            return true
        }

    /**
     * Formatted expiry date string.
     * Mirrors Swift's formattedExpiryDate computed property.
     */
    val formattedExpiryDate: String
        get() {
            val expDate = expirationDate ?: return "No expiry"
            val localDate = expDate.toLocalDateTime(TimeZone.currentSystemDefault())
            // Medium date style format
            val monthNames = listOf(
                "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
            )
            val month = monthNames.getOrElse(localDate.monthNumber - 1) { "???" }
            return "$month ${localDate.dayOfMonth}, ${localDate.year}"
        }

    /**
     * Convert to VoucherResponse for UI compatibility.
     * Mirrors Swift's toVoucherResponse() method.
     */
    fun toVoucherResponse(): VoucherResponse {
        return VoucherResponse(
            id = id,
            code = code,
            amount = amountValue,
            currency = "AUD",
            expiresAt = dateExpires,
            usageCount = usageCount,
            usageLimit = usageLimit ?: 0,
            status = if (isValid) "active" else "inactive"
        )
    }
}

/**
 * Custom serializer for usedBy field that can contain mixed Int/String values.
 * WooCommerce may return user IDs as integers or email strings.
 */
object UsedBySerializer : KSerializer<List<String>> {
    override val descriptor: SerialDescriptor = ListSerializer(String.serializer()).descriptor

    override fun deserialize(decoder: Decoder): List<String> {
        val jsonDecoder = decoder as? JsonDecoder
            ?: return emptyList()

        val element = jsonDecoder.decodeJsonElement()
        if (element !is JsonArray) return emptyList()

        return element.mapNotNull { item ->
            when (item) {
                is JsonPrimitive -> {
                    item.intOrNull?.toString() ?: item.content
                }
                else -> null
            }
        }
    }

    override fun serialize(encoder: Encoder, value: List<String>) {
        ListSerializer(String.serializer()).serialize(encoder, value)
    }
}

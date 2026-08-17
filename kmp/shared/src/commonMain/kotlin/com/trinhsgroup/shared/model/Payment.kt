package com.trinhsgroup.shared.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull

/**
 * Represents a WooCommerce payment method.
 * Mirrors the Swift Payment struct in PaymentModel.swift.
 *
 * Note: The `order` field can be either Int or String in the API response,
 * so we use a custom serializer to handle both cases.
 */
@Serializable
data class Payment(
    val id: String,
    val title: String = "",
    val description: String = "",
    val enabled: Boolean = false,
    @Serializable(with = IntOrStringSerializer::class)
    val order: Int = 0,
    @SerialName("method_title") val methodTitle: String = "",
    @SerialName("method_description") val methodDescription: String = ""
) {
    /**
     * Returns method_title if non-empty, otherwise falls back to title.
     */
    val displayTitle: String
        get() = if (methodTitle.isNotEmpty()) methodTitle else title

    /**
     * Returns method_description if non-empty, otherwise falls back to description.
     */
    val displayDescription: String
        get() = if (methodDescription.isNotEmpty()) methodDescription else description
}

/**
 * Custom serializer that handles both Int and String values for integer fields.
 * WooCommerce sometimes returns numeric fields as strings.
 */
object IntOrStringSerializer : KSerializer<Int> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("IntOrString", PrimitiveKind.STRING)

    override fun deserialize(decoder: Decoder): Int {
        val jsonDecoder = decoder as? JsonDecoder
        if (jsonDecoder != null) {
            val element = jsonDecoder.decodeJsonElement()
            if (element is JsonPrimitive) {
                // Try to decode as Int first
                element.intOrNull?.let { return it }
                // Fall back to parsing string as Int
                return element.content.toIntOrNull() ?: 0
            }
        }
        // Fallback for non-JSON decoders
        return try {
            decoder.decodeInt()
        } catch (e: Exception) {
            try {
                decoder.decodeString().toIntOrNull() ?: 0
            } catch (e2: Exception) {
                0
            }
        }
    }

    override fun serialize(encoder: Encoder, value: Int) {
        encoder.encodeInt(value)
    }
}

/**
 * Represents payment gateway settings.
 * Mirrors the Swift Setting struct in PaymentModel.swift.
 */
@Serializable
data class Setting(
    val instructions: SubSettings
)

/**
 * Represents sub-settings within a payment gateway setting.
 * Mirrors the Swift SubSettings struct in PaymentModel.swift.
 */
@Serializable
data class SubSettings(
    val value: String
)

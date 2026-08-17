package com.trinhsgroup.shared.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonEncoder
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.floatOrNull
import kotlinx.serialization.json.intOrNull

/**
 * A sealed class that represents a value that can be any of the following:
 * - Integer
 * - String
 * - Float
 * - Double
 * - Boolean
 * - Null
 *
 * Mirrors the Swift AnyCodableValue enum in Constant.swift.
 */
@Serializable(with = AnyCodableValueSerializer::class)
sealed class AnyCodableValue {
    data class IntegerValue(val value: Int) : AnyCodableValue()
    data class StringValue(val value: String) : AnyCodableValue()
    data class FloatValue(val value: Float) : AnyCodableValue()
    data class DoubleValue(val value: Double) : AnyCodableValue()
    data class BooleanValue(val value: Boolean) : AnyCodableValue()
    data object NullValue : AnyCodableValue()

    /**
     * Returns the string representation of the value.
     * Mirrors Swift's stringValue computed property.
     */
    val stringValue: String
        get() = when (this) {
            is StringValue -> value
            is IntegerValue -> value.toString()
            is DoubleValue -> value.toString()
            is FloatValue -> value.toString()
            is BooleanValue -> ""
            is NullValue -> ""
        }

    /**
     * Returns the integer representation of the value.
     * Mirrors Swift's intValue computed property.
     */
    val intValue: Int
        get() = when (this) {
            is IntegerValue -> value
            is StringValue -> value.toIntOrNull() ?: 0
            is FloatValue -> value.toInt()
            is DoubleValue -> value.toInt()
            is NullValue -> 0
            is BooleanValue -> 0
        }

    /**
     * Returns the float representation of the value.
     * Mirrors Swift's floatValue computed property.
     */
    val floatValue: Float
        get() = when (this) {
            is FloatValue -> value
            is IntegerValue -> value.toFloat()
            is StringValue -> value.toFloatOrNull() ?: 0f
            is DoubleValue -> value.toFloat()
            else -> 0f
        }

    /**
     * Returns the double representation of the value.
     * Mirrors Swift's doubleValue computed property.
     */
    val doubleValue: Double
        get() = when (this) {
            is DoubleValue -> value
            is StringValue -> value.toDoubleOrNull() ?: 0.0
            is IntegerValue -> value.toDouble()
            is FloatValue -> value.toDouble()
            else -> 0.0
        }

    /**
     * Returns the boolean representation of the value.
     * Mirrors Swift's booleanValue computed property.
     */
    val booleanValue: Boolean
        get() = when (this) {
            is BooleanValue -> value
            is IntegerValue -> value == 1
            is StringValue -> (value.toIntOrNull() ?: 0) == 1
            else -> false
        }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is AnyCodableValue) return false
        return when {
            this is IntegerValue && other is IntegerValue -> this.value == other.value
            this is StringValue && other is StringValue -> this.value == other.value
            this is FloatValue && other is FloatValue -> this.value == other.value
            this is DoubleValue && other is DoubleValue -> this.value == other.value
            this is BooleanValue && other is BooleanValue -> this.value == other.value
            this is NullValue && other is NullValue -> true
            else -> false
        }
    }

    override fun hashCode(): Int = when (this) {
        is IntegerValue -> value.hashCode()
        is StringValue -> value.hashCode()
        is FloatValue -> value.hashCode()
        is DoubleValue -> value.hashCode()
        is BooleanValue -> value.hashCode()
        is NullValue -> 0
    }
}

/**
 * Custom serializer for AnyCodableValue.
 * Handles decoding from JSON primitives (int, string, float, double, boolean, null).
 */
object AnyCodableValueSerializer : KSerializer<AnyCodableValue> {
    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("AnyCodableValue")

    override fun deserialize(decoder: Decoder): AnyCodableValue {
        val jsonDecoder = decoder as? JsonDecoder
            ?: return AnyCodableValue.NullValue

        val element = jsonDecoder.decodeJsonElement()
        return decodeFromJsonElement(element)
    }

    private fun decodeFromJsonElement(element: JsonElement): AnyCodableValue {
        return when (element) {
            is JsonNull -> AnyCodableValue.NullValue
            is JsonPrimitive -> {
                // Try to decode in order: Int -> String -> Float -> Double -> Boolean
                element.intOrNull?.let { return AnyCodableValue.IntegerValue(it) }
                element.booleanOrNull?.let { return AnyCodableValue.BooleanValue(it) }
                element.floatOrNull?.let { return AnyCodableValue.FloatValue(it) }
                element.doubleOrNull?.let { return AnyCodableValue.DoubleValue(it) }
                // Fall back to string
                AnyCodableValue.StringValue(element.content)
            }
            else -> AnyCodableValue.NullValue
        }
    }

    override fun serialize(encoder: Encoder, value: AnyCodableValue) {
        val jsonEncoder = encoder as? JsonEncoder
            ?: throw IllegalArgumentException("AnyCodableValue can only be serialized to JSON")

        val element = when (value) {
            is AnyCodableValue.IntegerValue -> JsonPrimitive(value.value)
            is AnyCodableValue.StringValue -> JsonPrimitive(value.value)
            is AnyCodableValue.FloatValue -> JsonPrimitive(value.value)
            is AnyCodableValue.DoubleValue -> JsonPrimitive(value.value)
            is AnyCodableValue.BooleanValue -> JsonPrimitive(value.value)
            is AnyCodableValue.NullValue -> JsonNull
        }
        jsonEncoder.encodeJsonElement(element)
    }
}

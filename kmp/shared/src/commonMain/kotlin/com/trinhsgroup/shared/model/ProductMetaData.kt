package com.trinhsgroup.shared.model

import kotlinx.serialization.Serializable

/**
 * Represents product metadata from WooCommerce.
 * Mirrors the Swift ProductMetaData struct in ProductModel.swift.
 */
@Serializable
data class ProductMetaData(
    val id: Int,
    val key: String,
    val value: AnyCodableValue
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ProductMetaData) return false
        return key == other.key && value == other.value
    }

    override fun hashCode(): Int {
        var result = key.hashCode()
        result = 31 * result + value.hashCode()
        return result
    }
}

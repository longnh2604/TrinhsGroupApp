package com.trinhsgroup.shared.model

/**
 * Represents a product add-on option from Firestore.
 * Mirrors the Swift ProductAddOns struct.
 *
 * Note: This is used for Firestore data, not WooCommerce API.
 * The Firestore document structure has:
 * - categoryId: array of category IDs this addon applies to
 * - productId: specific product ID (optional)
 * - content: display name of the addon
 * - value: price value in cents
 */
data class ProductAddOns(
    val id: Int = 0,
    val productId: Int = 0,
    val content: String = "",
    val value: Int = 0,
    var checked: Boolean = false
) {
    companion object {
        /**
         * Creates a ProductAddOns from a Firestore document map.
         */
        fun fromMap(map: Map<String, Any?>): ProductAddOns {
            return ProductAddOns(
                id = (map["categoryId"] as? Number)?.toInt() ?: 0,
                productId = (map["productId"] as? Number)?.toInt() ?: 0,
                content = map["content"] as? String ?: "",
                value = (map["value"] as? Number)?.toInt() ?: 0,
                checked = false
            )
        }
    }
}

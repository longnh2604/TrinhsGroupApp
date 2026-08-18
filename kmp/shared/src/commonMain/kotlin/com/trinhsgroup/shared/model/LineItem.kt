package com.trinhsgroup.shared.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a line item in a WooCommerce order.
 * Mirrors the Swift LineItem struct in OrderModel.swift.
 */
@Serializable
data class LineItem(
    val id: Int,
    val name: String,
    @SerialName("product_id") val productId: Int,
    val quantity: Int,
    val subtotal: String,
    val total: String,
    val price: Double,
    /**
     * Add-on selections and the customer's note, exactly as they were sent at checkout.
     * Defaulted because Woo omits it on plain products, and a line of add-on labels is not
     * worth failing a customer's whole order history over.
     */
    @SerialName("meta_data") val metaData: List<ProductMetaData> = emptyList()
) {
    /**
     * Add-on selections, customer-facing only.
     *
     * WooCommerce's internal line-item meta is underscore-prefixed (`_note`,
     * `_reduced_stock`) and must never render as something the customer chose.
     */
    val addOns: List<ProductMetaData>
        get() = metaData.filter { !it.key.startsWith("_") }

    /**
     * What the customer actually chose, one entry per option group, in the order the server
     * listed them.
     *
     * The two order paths spell an add-on the opposite way round:
     *
     * - Web (YITH) puts the group label in the key and the choice in the value — `"1st Pho"` /
     *   `"Beef"`. A ticked checkbox group repeats the key once per option, so `"Addition"`
     *   arrives three times with three values; grouping turns that into one readable line.
     * - The old app path put the choice in the key and its price in the value — `"Extra beef"`
     *   / `"3"`.
     *
     * So a value that parses as a number is a price, never a label, and is dropped — rendering
     * it would show a charge that path never actually billed. An empty value means YITH stored
     * the option without a display value, and there too the key is the choice.
     */
    val addOnLabels: List<String>
        get() {
            val groups = mutableListOf<String>()
            val choices = mutableMapOf<String, MutableList<String>>()

            for (meta in addOns) {
                if (choices[meta.key] == null) {
                    groups.add(meta.key)
                    choices[meta.key] = mutableListOf()
                }
                val chosen = meta.value.stringValue.trim()
                if (chosen.isEmpty() || chosen.toDoubleOrNull() != null) continue
                choices[meta.key]?.add(chosen)
            }

            return groups.map { key ->
                val picked = choices[key]
                if (picked.isNullOrEmpty()) key else "$key: ${picked.joinToString(", ")}"
            }
        }

    /** The customer's free-text note for this line. Blank reads as absent. */
    val note: String?
        get() = metaData.firstOrNull { it.key == "_note" }
            ?.value?.stringValue
            ?.takeIf { it.isNotBlank() }

    companion object {
        val Default = LineItem(
            id = 0,
            name = "",
            productId = 0,
            quantity = 0,
            subtotal = "0",
            total = "0",
            price = 0.0
        )
    }
}

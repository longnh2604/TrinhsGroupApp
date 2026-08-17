package com.trinhsgroup.shared.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.descriptors.element
import kotlinx.serialization.encoding.CompositeDecoder
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonPrimitive

/**
 * Represents a WooCommerce product.
 * Mirrors the Swift Product struct in ProductModel.swift.
 *
 * Note: WooCommerce returns price fields as strings, so we use custom deserialization.
 */
@Serializable(with = ProductSerializer::class)
data class Product(
    val id: Int,
    val name: String,
    @SerialName("short_description") val shortDescription: String = "",
    val description: String = "",
    val price: Double = 0.0,
    @SerialName("regular_price") val regularPrice: Double = 0.0,
    @SerialName("sale_price") val salePrice: Double = 0.0,
    val images: List<WooImage> = emptyList(),
    val quantity: Int = 0,
    val attributes: List<Attribute> = emptyList(),
    val categories: List<Category> = emptyList(),
    @SerialName("meta_data") val metaData: List<ProductMetaData> = emptyList(),
    val color: String = "",
    val size: String = ""
) {
    /**
     * Calculates the total price based on price and quantity.
     * Mirrors Swift's totalPrice computed property.
     */
    val totalPrice: Double
        get() = price * quantity

    /**
     * Creates a unique identifier for the product in the cart.
     * This is used to differentiate the same product with different add-ons/options.
     * Mirrors Swift's cartIdentifier computed property.
     *
     * The metadata is sorted by key to ensure the identifier is order-independent.
     */
    val cartIdentifier: String
        get() {
            // Always sort to make the identifier order-independent!
            val metaString = metaData
                .sortedBy { it.key }
                .joinToString("&") { "${it.key}=${it.value.stringValue}" }
            return "$name|$metaString"
        }

    /**
     * Returns product add-ons only (excluding internal metadata).
     * Mirrors Swift's getProductAddonOnly() method.
     *
     * Note: The Swift logic is `!key.contains("_") || !key.contains("epafw")`.
     * This means: keep items where key does NOT contain "_" OR key does NOT contain "epafw"
     * Since almost all keys either don't contain "_" or don't contain "epafw",
     * this effectively filters out only keys that contain BOTH "_" AND "epafw".
     */
    fun getProductAddonOnly(): List<ProductMetaData> {
        return metaData.filter { !it.key.contains("_") || !it.key.contains("epafw") }
    }

    /**
     * Creates a copy with updated quantity.
     */
    fun withQuantity(newQuantity: Int): Product = copy(quantity = newQuantity)
}

/**
 * Custom serializer for Product that handles WooCommerce's string price fields.
 */
object ProductSerializer : KSerializer<Product> {
    override val descriptor: SerialDescriptor = buildClassSerialDescriptor("Product") {
        element<Int>("id")
        element<String>("name")
        element<String>("short_description")
        element<String>("description")
        element<String>("price")
        element<String>("regular_price")
        element<String>("sale_price")
        element<JsonArray>("images")
        element<JsonArray>("attributes")
        element<JsonArray>("categories")
        element<JsonArray>("meta_data")
    }

    override fun deserialize(decoder: Decoder): Product {
        val jsonDecoder = decoder as? JsonDecoder
            ?: throw IllegalArgumentException("Product can only be deserialized from JSON")

        val jsonObject = jsonDecoder.decodeJsonElement() as? JsonObject
            ?: throw IllegalArgumentException("Expected JsonObject for Product")

        val json = jsonDecoder.json

        val id = jsonObject["id"]?.jsonPrimitive?.int ?: 0
        val name = jsonObject["name"]?.jsonPrimitive?.contentOrNull ?: ""
        val shortDescription = jsonObject["short_description"]?.jsonPrimitive?.contentOrNull ?: ""
        val description = jsonObject["description"]?.jsonPrimitive?.contentOrNull ?: ""

        // Handle price conversion from String to Double
        val priceString = jsonObject["price"]?.jsonPrimitive?.contentOrNull ?: "0"
        val price = priceString.toDoubleOrNull() ?: 0.0

        val regularPriceString = jsonObject["regular_price"]?.jsonPrimitive?.contentOrNull ?: "0"
        val regularPrice = regularPriceString.toDoubleOrNull() ?: 0.0

        val salePriceString = jsonObject["sale_price"]?.jsonPrimitive?.contentOrNull ?: ""
        val salePrice = salePriceString.toDoubleOrNull() ?: 0.0

        val images = jsonObject["images"]?.let { json.decodeFromJsonElement<List<WooImage>>(it) } ?: emptyList()
        val attributes = jsonObject["attributes"]?.let { json.decodeFromJsonElement<List<Attribute>>(it) } ?: emptyList()
        val categories = jsonObject["categories"]?.let { json.decodeFromJsonElement<List<Category>>(it) } ?: emptyList()
        val metaData = jsonObject["meta_data"]?.let { json.decodeFromJsonElement<List<ProductMetaData>>(it) } ?: emptyList()

        return Product(
            id = id,
            name = name,
            shortDescription = shortDescription,
            description = description,
            price = price,
            regularPrice = regularPrice,
            salePrice = salePrice,
            images = images,
            attributes = attributes,
            categories = categories,
            metaData = metaData
        )
    }

    override fun serialize(encoder: Encoder, value: Product) {
        val composite = encoder.beginStructure(descriptor)
        composite.encodeIntElement(descriptor, 0, value.id)
        composite.encodeStringElement(descriptor, 1, value.name)
        composite.encodeStringElement(descriptor, 2, value.shortDescription)
        composite.encodeStringElement(descriptor, 3, value.description)
        composite.encodeStringElement(descriptor, 4, value.price.toString())
        composite.encodeStringElement(descriptor, 5, value.regularPrice.toString())
        composite.encodeStringElement(descriptor, 6, value.salePrice.toString())
        // For serialization, we'd need to implement list serialization
        // This is typically not needed for API responses
        composite.endStructure(descriptor)
    }
}

package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Unit tests for Product model.
 * Tests cartIdentifier stability, totalPrice calculation, and getProductAddonOnly filtering.
 */
class ProductTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    @Test
    fun testCartIdentifierStability() {
        val metaData = listOf(
            ProductMetaData(1, "size", AnyCodableValue.StringValue("large")),
            ProductMetaData(2, "color", AnyCodableValue.StringValue("red"))
        )
        
        val product = Product(
            id = 1,
            name = "Test Product",
            metaData = metaData,
            quantity = 1
        )
        
        // Call cartIdentifier multiple times, should be the same
        val id1 = product.cartIdentifier
        val id2 = product.cartIdentifier
        assertEquals(id1, id2, "cartIdentifier should be stable across calls")
    }

    @Test
    fun testCartIdentifierMetadataSorting() {
        // Create two products with same metadata but in different order
        val metaData1 = listOf(
            ProductMetaData(1, "size", AnyCodableValue.StringValue("large")),
            ProductMetaData(2, "color", AnyCodableValue.StringValue("red"))
        )
        
        val metaData2 = listOf(
            ProductMetaData(2, "color", AnyCodableValue.StringValue("red")),
            ProductMetaData(1, "size", AnyCodableValue.StringValue("large"))
        )
        
        val product1 = Product(id = 1, name = "Test Product", metaData = metaData1, quantity = 1)
        val product2 = Product(id = 1, name = "Test Product", metaData = metaData2, quantity = 1)
        
        // cartIdentifier should be the same regardless of metadata order
        assertEquals(
            product1.cartIdentifier, 
            product2.cartIdentifier,
            "cartIdentifier should be order-independent (sorted by key)"
        )
    }

    @Test
    fun testCartIdentifierFormat() {
        val metaData = listOf(
            ProductMetaData(1, "addon", AnyCodableValue.StringValue("extra cheese")),
            ProductMetaData(2, "size", AnyCodableValue.StringValue("large"))
        )
        
        val product = Product(id = 1, name = "Pizza", metaData = metaData, quantity = 1)
        
        // Format: name|key1=value1&key2=value2 (sorted by key)
        val expected = "Pizza|addon=extra cheese&size=large"
        assertEquals(expected, product.cartIdentifier)
    }

    @Test
    fun testCartIdentifierEmptyMetadata() {
        val product = Product(id = 1, name = "Simple Product", metaData = emptyList(), quantity = 1)
        assertEquals("Simple Product|", product.cartIdentifier)
    }

    @Test
    fun testTotalPrice() {
        val product = Product(id = 1, name = "Test", price = 10.0, quantity = 3)
        assertEquals(30.0, product.totalPrice)
    }

    @Test
    fun testTotalPriceZeroQuantity() {
        val product = Product(id = 1, name = "Test", price = 10.0, quantity = 0)
        assertEquals(0.0, product.totalPrice)
    }

    @Test
    fun testGetProductAddonOnly() {
        val metaData = listOf(
            ProductMetaData(1, "addon", AnyCodableValue.StringValue("cheese")),
            ProductMetaData(2, "_internal", AnyCodableValue.StringValue("hidden")),
            ProductMetaData(3, "size", AnyCodableValue.StringValue("large")),
            ProductMetaData(4, "_epafw_setting", AnyCodableValue.StringValue("config"))
        )
        
        val product = Product(id = 1, name = "Test", metaData = metaData, quantity = 1)
        val addons = product.getProductAddonOnly()
        
        // The Swift logic is: !key.contains("_") || !key.contains("epafw")
        // This keeps items where key does NOT contain "_" OR key does NOT contain "epafw"
        // So "_internal" is kept because it doesn't contain "epafw"
        // And "_epafw_setting" is filtered out because it contains both "_" AND "epafw"
        
        // addon - no "_", no "epafw" -> kept (true || true = true)
        // _internal - has "_", no "epafw" -> kept (false || true = true)
        // size - no "_", no "epafw" -> kept (true || true = true)
        // _epafw_setting - has "_", has "epafw" -> filtered (false || false = false)
        
        assertEquals(3, addons.size)
        assertTrue(addons.any { it.key == "addon" })
        assertTrue(addons.any { it.key == "_internal" })
        assertTrue(addons.any { it.key == "size" })
        assertFalse(addons.any { it.key == "_epafw_setting" })
    }

    @Test
    fun testProductJsonDecoding() {
        val jsonStr = """
        {
            "id": 123,
            "name": "Test Product",
            "short_description": "Short desc",
            "description": "Long description",
            "price": "19.99",
            "regular_price": "24.99",
            "sale_price": "19.99",
            "images": [{"id": 1, "src": "http://example.com/image.jpg"}],
            "attributes": [],
            "categories": [],
            "meta_data": []
        }
        """
        
        val product = json.decodeFromString<Product>(jsonStr)
        
        assertEquals(123, product.id)
        assertEquals("Test Product", product.name)
        assertEquals("Short desc", product.shortDescription)
        assertEquals("Long description", product.description)
        assertEquals(19.99, product.price)
        assertEquals(24.99, product.regularPrice)
        assertEquals(19.99, product.salePrice)
        assertEquals(1, product.images.size)
    }

    @Test
    fun testProductJsonDecodingWithEmptySalePrice() {
        val jsonStr = """
        {
            "id": 123,
            "name": "Test Product",
            "short_description": "",
            "description": "",
            "price": "19.99",
            "regular_price": "19.99",
            "sale_price": "",
            "images": [],
            "attributes": [],
            "categories": [],
            "meta_data": []
        }
        """
        
        val product = json.decodeFromString<Product>(jsonStr)
        
        assertEquals(0.0, product.salePrice, "Empty sale_price should decode to 0.0")
    }

    @Test
    fun testProductWithMetadata() {
        val jsonStr = """
        {
            "id": 123,
            "name": "Pizza",
            "short_description": "",
            "description": "",
            "price": "15.00",
            "regular_price": "15.00",
            "sale_price": "",
            "images": [],
            "attributes": [],
            "categories": [],
            "meta_data": [
                {"id": 1, "key": "size", "value": "large"},
                {"id": 2, "key": "toppings", "value": "pepperoni"}
            ]
        }
        """
        
        val product = json.decodeFromString<Product>(jsonStr)
        
        assertEquals(2, product.metaData.size)
        assertEquals("size", product.metaData[0].key)
        assertEquals("large", product.metaData[0].value.stringValue)
    }

    @Test
    fun testWithQuantity() {
        val product = Product(id = 1, name = "Test", price = 10.0, quantity = 1)
        val updated = product.withQuantity(5)
        
        assertEquals(1, product.quantity, "Original should be unchanged")
        assertEquals(5, updated.quantity, "New product should have updated quantity")
        assertEquals(50.0, updated.totalPrice)
    }
}

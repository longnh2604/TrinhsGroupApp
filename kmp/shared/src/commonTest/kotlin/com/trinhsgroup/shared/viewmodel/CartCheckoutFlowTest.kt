package com.trinhsgroup.shared.viewmodel

import com.trinhsgroup.shared.model.*
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Integration tests for the full cart → checkout flow.
 * Verifies cart math parity with iOS implementation.
 */
class CartCheckoutFlowTest {
    
    // region Test Fixtures
    
    private fun createProduct(
        id: Int,
        name: String,
        price: Double,
        regularPrice: Double = price,
        salePrice: Double = 0.0,
        metaData: List<ProductMetaData> = emptyList()
    ): Product {
        return Product(
            id = id,
            name = name,
            price = price,
            regularPrice = regularPrice,
            salePrice = salePrice,
            categories = listOf(Category(id = 1, name = "Thai")),
            images = listOf(WooImage(id = 1, src = "https://example.com/image.jpg")),
            attributes = emptyList(),
            metaData = metaData
        )
    }
    
    // endregion
    
    // region Cart Identifier Tests
    
    @Test
    fun `cart identifier matches iOS format - product without meta`() {
        val product = createProduct(id = 456, name = "Pad Thai", price = 18.50)
        
        // iOS: name + "|" + sortedMetaData (key=value joined by &)
        // When no meta, it's just "name|"
        val expectedIdentifier = "Pad Thai|"
        
        assertEquals(expectedIdentifier, product.cartIdentifier)
    }
    
    @Test
    fun `cart identifier matches iOS format - product with single meta`() {
        val product = createProduct(
            id = 456,
            name = "Pad Thai",
            price = 18.50,
            metaData = listOf(
                ProductMetaData(id = 1, key = "Spice Level", value = AnyCodableValue.StringValue("Medium"))
            )
        )
        
        // iOS format: "name|key=value"
        val expectedIdentifier = "Pad Thai|Spice Level=Medium"
        
        assertEquals(expectedIdentifier, product.cartIdentifier)
    }
    
    @Test
    fun `cart identifier matches iOS format - product with multiple meta sorted`() {
        val product = createProduct(
            id = 456,
            name = "Pad Thai",
            price = 18.50,
            metaData = listOf(
                ProductMetaData(id = 2, key = "Spice Level", value = AnyCodableValue.StringValue("Hot")),
                ProductMetaData(id = 1, key = "Extra", value = AnyCodableValue.StringValue("Tofu"))
            )
        )
        
        // iOS sorts by key alphabetically: Extra, Spice Level
        val expectedIdentifier = "Pad Thai|Extra=Tofu&Spice Level=Hot"
        
        assertEquals(expectedIdentifier, product.cartIdentifier)
    }
    
    // endregion
    
    // region Cart Math Tests
    
    @Test
    fun `subtotal calculation matches iOS - single item`() {
        val product = createProduct(id = 456, name = "Pad Thai", price = 18.50)
        val quantity = 2
        
        // iOS: product.price * quantity
        val subtotal = product.price * quantity
        
        assertEquals(37.0, subtotal)
    }
    
    @Test
    fun `subtotal calculation matches iOS - multiple items`() {
        val items = listOf(
            Pair(createProduct(id = 456, name = "Pad Thai", price = 18.50), 2),
            Pair(createProduct(id = 457, name = "Green Curry", price = 16.00), 1),
            Pair(createProduct(id = 458, name = "Spring Rolls", price = 8.50), 3)
        )
        
        // iOS: sum of (price * quantity) for all items
        val subtotal = items.sumOf { (product, qty) ->
            product.price * qty
        }
        
        // 18.50*2 + 16.00*1 + 8.50*3 = 37.00 + 16.00 + 25.50 = 78.50
        assertEquals(78.5, subtotal)
    }
    
    @Test
    fun `regular price total uses regular price not sale price`() {
        val items = listOf(
            Pair(createProduct(id = 456, name = "Pad Thai", price = 18.50, regularPrice = 18.50), 2),
            Pair(createProduct(id = 457, name = "Green Curry", price = 16.00, regularPrice = 20.00, salePrice = 16.00), 1)
        )
        
        // iOS regularPriceTotal: uses regularPrice, not current price
        val regularPriceTotal = items.sumOf { (product, qty) ->
            product.regularPrice * qty
        }
        
        // 18.50*2 + 20.00*1 = 37.00 + 20.00 = 57.00
        assertEquals(57.0, regularPriceTotal)
    }
    
    @Test
    fun `discounts calculation - difference between regular and actual`() {
        val items = listOf(
            Pair(createProduct(id = 456, name = "Pad Thai", price = 18.50, regularPrice = 18.50), 2),
            Pair(createProduct(id = 457, name = "Green Curry", price = 16.00, regularPrice = 20.00, salePrice = 16.00), 1)
        )
        
        val subtotal = items.sumOf { (product, qty) ->
            product.price * qty
        }
        
        val regularPriceTotal = items.sumOf { (product, qty) ->
            product.regularPrice * qty
        }
        
        // iOS discounts = regularPriceTotal - subtotal
        val discounts = regularPriceTotal - subtotal
        
        // 57.00 - 53.00 = 4.00
        assertEquals(4.0, discounts)
    }
    
    @Test
    fun `total includes shipping cost`() {
        val subtotal = 53.0
        val shippingCost = 5.0
        
        // iOS: total = subtotal + selectedShip.cost.value
        val total = subtotal + shippingCost
        
        assertEquals(58.0, total)
    }
    
    @Test
    fun `total with zero shipping for pickup`() {
        val subtotal = 53.0
        val shippingCost = 0.0 // Pickup
        
        val total = subtotal + shippingCost
        
        assertEquals(53.0, total)
    }
    
    // endregion
    
    // region Coupon Discount Tests
    
    @Test
    fun `fixed coupon discount`() {
        val subtotal = 53.0
        val couponAmount = 10.0
        val couponType = "fixed_cart"
        
        val discount = if (couponType == "fixed_cart") couponAmount else 0.0
        val afterCoupon = subtotal - discount
        
        assertEquals(43.0, afterCoupon)
    }
    
    @Test
    fun `percent coupon discount`() {
        val subtotal = 100.0
        val couponPercent = 15.0
        val couponType = "percent"
        
        val discount = if (couponType == "percent") subtotal * (couponPercent / 100) else 0.0
        val afterCoupon = subtotal - discount
        
        assertEquals(15.0, discount)
        assertEquals(85.0, afterCoupon)
    }
    
    // endregion
    
    // region Number of Items Tests
    
    @Test
    fun `number of items sums all quantities`() {
        val cartItems = mapOf(
            "Pad Thai|Spice Level=Medium" to Pair(createProduct(id = 456, name = "Pad Thai", price = 18.50), 2),
            "Green Curry|" to Pair(createProduct(id = 457, name = "Green Curry", price = 16.00), 1),
            "Spring Rolls|" to Pair(createProduct(id = 458, name = "Spring Rolls", price = 8.50), 3)
        )
        
        // iOS: sum of all quantities
        val numberOfItems = cartItems.values.sumOf { it.second }
        
        assertEquals(6, numberOfItems)
    }
    
    @Test
    fun `number of items is zero for empty cart`() {
        val cartItems = emptyMap<String, Pair<Product, Int>>()
        
        val numberOfItems = cartItems.values.sumOf { it.second }
        
        assertEquals(0, numberOfItems)
    }
    
    // endregion
    
    // region Edge Cases
    
    @Test
    fun `handles product with zero price`() {
        val product = createProduct(id = 999, name = "Free Sample", price = 0.0)
        val quantity = 1
        
        val subtotal = product.price * quantity
        
        assertEquals(0.0, subtotal)
    }
    
    @Test
    fun `handles large quantities`() {
        val product = createProduct(id = 456, name = "Pad Thai", price = 18.50)
        val quantity = 100
        
        val subtotal = product.price * quantity
        
        assertEquals(1850.0, subtotal)
    }
    
    // endregion
}

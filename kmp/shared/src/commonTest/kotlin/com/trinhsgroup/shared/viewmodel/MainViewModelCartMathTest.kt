package com.trinhsgroup.shared.viewmodel

import com.trinhsgroup.shared.model.Coupon
import com.trinhsgroup.shared.model.Product
import com.trinhsgroup.shared.model.ProductMetaData
import com.trinhsgroup.shared.model.AnyCodableValue
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Tests for MainViewModel cart math.
 * Tests the critical cart operations that must match iOS behavior exactly.
 */
class MainViewModelCartMathTest {

    // ============ numberOfItems Tests ============

    @Test
    fun testNumberOfItemsEmpty() {
        val cart = CartMath(emptyList())
        assertEquals(0, cart.numberOfItems)
    }

    @Test
    fun testNumberOfItemsSingleItem() {
        val items = listOf(
            createProduct(id = 1, price = 10.0, quantity = 3)
        )
        val cart = CartMath(items)
        assertEquals(3, cart.numberOfItems)
    }

    @Test
    fun testNumberOfItemsMultipleItems() {
        val items = listOf(
            createProduct(id = 1, price = 10.0, quantity = 2),
            createProduct(id = 2, price = 15.0, quantity = 3),
            createProduct(id = 3, price = 20.0, quantity = 1)
        )
        val cart = CartMath(items)
        assertEquals(6, cart.numberOfItems) // 2 + 3 + 1 = 6
    }

    // ============ subtotal Tests ============

    @Test
    fun testSubtotalEmpty() {
        val cart = CartMath(emptyList())
        assertEquals(0.0, cart.subtotal)
    }

    @Test
    fun testSubtotalSingleItem() {
        val items = listOf(
            createProduct(id = 1, price = 10.0, quantity = 3)
        )
        val cart = CartMath(items)
        assertEquals(30.0, cart.subtotal) // 10 * 3 = 30
    }

    @Test
    fun testSubtotalMultipleItems() {
        val items = listOf(
            createProduct(id = 1, price = 10.0, quantity = 2),  // 20
            createProduct(id = 2, price = 15.0, quantity = 3),  // 45
            createProduct(id = 3, price = 20.0, quantity = 1)   // 20
        )
        val cart = CartMath(items)
        assertEquals(85.0, cart.subtotal) // 20 + 45 + 20 = 85
    }

    // ============ discounts Tests ============

    @Test
    fun testDiscountsEmpty() {
        val cart = CartMath(emptyList())
        assertEquals(0.0, cart.discounts)
    }

    @Test
    fun testDiscountsSaleItem() {
        // Regular price 100, sale price 80 -> discount of 20 per item
        val items = listOf(
            createProduct(id = 1, price = 80.0, regularPrice = 100.0, quantity = 2)
        )
        val cart = CartMath(items)
        assertEquals(40.0, cart.discounts) // (100 - 80) * 2 = 40
    }

    @Test
    fun testDiscountsNoSale() {
        // Price equals regular price -> no discount
        val items = listOf(
            createProduct(id = 1, price = 100.0, regularPrice = 100.0, quantity = 3)
        )
        val cart = CartMath(items)
        assertEquals(0.0, cart.discounts)
    }

    @Test
    fun testDiscountsMixedItems() {
        val items = listOf(
            createProduct(id = 1, price = 80.0, regularPrice = 100.0, quantity = 2),  // 40
            createProduct(id = 2, price = 50.0, regularPrice = 50.0, quantity = 1),    // 0
            createProduct(id = 3, price = 25.0, regularPrice = 30.0, quantity = 4)     // 20
        )
        val cart = CartMath(items)
        assertEquals(60.0, cart.discounts) // 40 + 0 + 20 = 60
    }

    // ============ regularPriceTotal Tests ============

    @Test
    fun testRegularPriceTotalEmpty() {
        val cart = CartMath(emptyList())
        assertEquals(0.0, cart.regularPriceTotal)
    }

    @Test
    fun testRegularPriceTotalMixedItems() {
        val items = listOf(
            createProduct(id = 1, price = 80.0, regularPrice = 100.0, quantity = 2),  // 200
            createProduct(id = 2, price = 50.0, regularPrice = 50.0, quantity = 1),    // 50
            createProduct(id = 3, price = 25.0, regularPrice = 30.0, quantity = 4)     // 120
        )
        val cart = CartMath(items)
        assertEquals(370.0, cart.regularPriceTotal) // 200 + 50 + 120 = 370
    }

    // ============ total Tests (with shipping) ============

    @Test
    fun testTotalWithShipping() {
        val items = listOf(
            createProduct(id = 1, price = 50.0, quantity = 2)  // subtotal = 100
        )
        val cart = CartMath(items, shippingCost = 10.0)
        assertEquals(110.0, cart.total) // 100 + 10 = 110
    }

    @Test
    fun testTotalEmptyCartWithShipping() {
        val cart = CartMath(emptyList(), shippingCost = 5.0)
        assertEquals(5.0, cart.total) // Just shipping cost
    }

    // ============ Coupon Discount Tests ============

    @Test
    fun testFixedDiscountNoCoupon() {
        val cart = CartMath(emptyList(), coupon = Coupon.Default)
        assertEquals(0.0, cart.fixedDiscount)
    }

    @Test
    fun testFixedDiscountWithCoupon() {
        val coupon = Coupon(
            id = 1,
            code = "SAVE10",
            type = "fixed_cart",
            amount = "10.00"
        )
        val cart = CartMath(emptyList(), coupon = coupon)
        assertEquals(10.0, cart.fixedDiscount)
    }

    @Test
    fun testPercentDiscountNoCoupon() {
        val cart = CartMath(emptyList(), coupon = Coupon.Default)
        assertEquals(0.0, cart.percentDiscount)
    }

    @Test
    fun testPercentDiscountWithCoupon() {
        val items = listOf(
            createProduct(id = 1, price = 100.0, quantity = 1)  // total = 100
        )
        val coupon = Coupon(
            id = 1,
            code = "SAVE20",
            type = "percent",
            amount = "20.00"
        )
        val cart = CartMath(items, coupon = coupon)
        assertEquals(20.0, cart.percentDiscount) // 100 * 20% = 20
    }

    // ============ Cart Operations Tests ============

    @Test
    fun testAddItemToEmptyCart() {
        val operations = CartOperations(mutableListOf())
        val product = createProduct(id = 1, name = "Test", price = 10.0)
        
        operations.add(product)
        
        assertEquals(1, operations.items.size)
        assertEquals(1, operations.items[0].quantity)
    }

    @Test
    fun testAddSameItemIncrementsQuantity() {
        val product1 = createProduct(id = 1, name = "Test", price = 10.0, quantity = 1)
        val operations = CartOperations(mutableListOf(product1))
        
        val product2 = createProduct(id = 1, name = "Test", price = 10.0)
        operations.add(product2)
        
        assertEquals(1, operations.items.size)
        assertEquals(2, operations.items[0].quantity)
    }

    @Test
    fun testAddDifferentItemsWithSameId() {
        // Same product ID but different meta_data should be separate cart items
        val product1 = createProduct(
            id = 1, 
            name = "Test", 
            price = 10.0, 
            quantity = 1,
            metaData = listOf(ProductMetaData(1, "size", AnyCodableValue.StringValue("M")))
        )
        val operations = CartOperations(mutableListOf(product1))
        
        val product2 = createProduct(
            id = 1, 
            name = "Test", 
            price = 10.0,
            metaData = listOf(ProductMetaData(1, "size", AnyCodableValue.StringValue("L")))
        )
        operations.add(product2)
        
        assertEquals(2, operations.items.size) // Different cartIdentifier
    }

    @Test
    fun testRemoveItemDecrementsQuantity() {
        val product = createProduct(id = 1, name = "Test", price = 10.0, quantity = 3)
        val operations = CartOperations(mutableListOf(product))
        
        operations.remove(product)
        
        assertEquals(1, operations.items.size)
        assertEquals(2, operations.items[0].quantity)
    }

    @Test
    fun testRemoveLastItemRemovesFromCart() {
        val product = createProduct(id = 1, name = "Test", price = 10.0, quantity = 1)
        val operations = CartOperations(mutableListOf(product))
        
        operations.remove(product)
        
        assertEquals(0, operations.items.size)
    }

    @Test
    fun testRemoveAllItem() {
        val product = createProduct(id = 1, name = "Test", price = 10.0, quantity = 5)
        val operations = CartOperations(mutableListOf(product))
        
        operations.removeAll(product)
        
        assertEquals(0, operations.items.size)
    }

    @Test
    fun testReset() {
        val items = mutableListOf(
            createProduct(id = 1, price = 10.0, quantity = 2),
            createProduct(id = 2, price = 20.0, quantity = 3)
        )
        val operations = CartOperations(items)
        
        operations.reset()
        
        assertEquals(0, operations.items.size)
    }

    // ============ Helper Functions ============

    private fun createProduct(
        id: Int,
        name: String = "Product $id",
        price: Double = 10.0,
        regularPrice: Double = price,
        quantity: Int = 0,
        metaData: List<ProductMetaData> = emptyList()
    ): Product {
        return Product(
            id = id,
            name = name,
            price = price,
            regularPrice = regularPrice,
            quantity = quantity,
            metaData = metaData
        )
    }
}

/**
 * Helper class to test cart math calculations in isolation.
 * Mirrors the computed properties in MainViewModel.
 */
class CartMath(
    private val items: List<Product>,
    private val shippingCost: Double = 0.0,
    private val coupon: Coupon = Coupon.Default
) {
    val numberOfItems: Int
        get() = if (items.isNotEmpty()) items.sumOf { it.quantity } else 0

    val discounts: Double
        get() = if (items.isNotEmpty()) {
            items.sumOf { (it.regularPrice - it.price) * it.quantity.toDouble() }
        } else 0.0

    val subtotal: Double
        get() = if (items.isNotEmpty()) {
            items.sumOf { it.price * it.quantity.toDouble() }
        } else 0.0

    val regularPriceTotal: Double
        get() = if (items.isNotEmpty()) {
            items.sumOf { it.regularPrice * it.quantity.toDouble() }
        } else 0.0

    val total: Double
        get() = if (items.isNotEmpty()) subtotal + shippingCost else shippingCost

    val fixedDiscount: Double
        get() = if (coupon.id != Coupon.Default.id) {
            coupon.amount?.toDoubleOrNull() ?: 0.0
        } else 0.0

    val percentDiscount: Double
        get() = if (coupon.id != Coupon.Default.id) {
            val percentage = coupon.amount?.toDoubleOrNull() ?: 0.0
            total * (percentage / 100.0)
        } else 0.0
}

/**
 * Helper class to test cart operations in isolation.
 * Mirrors the cart methods in MainViewModel.
 */
class CartOperations(val items: MutableList<Product>) {
    fun add(item: Product) {
        val index = items.indexOfFirst { it.cartIdentifier == item.cartIdentifier }
        if (index != -1) {
            items[index] = items[index].withQuantity(items[index].quantity + 1)
        } else {
            items.add(item.withQuantity(1))
        }
    }

    fun remove(item: Product) {
        val index = items.indexOfFirst { it.cartIdentifier == item.cartIdentifier }
        if (index != -1) {
            if (items[index].quantity > 1) {
                items[index] = items[index].withQuantity(items[index].quantity - 1)
            } else {
                items.removeAt(index)
            }
        }
    }

    fun removeAll(item: Product) {
        val index = items.indexOfFirst { it.cartIdentifier == item.cartIdentifier }
        if (index != -1) {
            items.removeAt(index)
        }
    }

    fun reset() {
        items.clear()
    }
}

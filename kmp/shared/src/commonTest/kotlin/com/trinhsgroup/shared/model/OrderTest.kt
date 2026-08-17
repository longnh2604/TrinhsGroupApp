package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Unit tests for Order model.
 * Tests subtotal, discount calculations, and default object.
 */
class OrderTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    @Test
    fun testOrderSubtotal() {
        val lineItems = listOf(
            LineItem(id = 1, name = "Item 1", productId = 1, quantity = 2, subtotal = "20.00", total = "20.00", price = 10.0),
            LineItem(id = 2, name = "Item 2", productId = 2, quantity = 1, subtotal = "15.50", total = "15.50", price = 15.5)
        )
        
        val order = Order(
            id = 1,
            number = "001",
            status = "processing",
            dateCreated = "",
            dateModified = "",
            discountTotal = "0",
            total = "35.50",
            customerNote = "",
            billing = Billing.Empty,
            shipping = Shipping.Empty,
            paymentMethodTitle = "Credit Card",
            lineItems = lineItems,
            shippingLines = emptyList()
        )
        
        assertEquals(35.50, order.subtotal, 0.01)
    }

    @Test
    fun testOrderDiscount() {
        val order = Order(
            id = 1,
            number = "001",
            status = "processing",
            dateCreated = "",
            dateModified = "",
            discountTotal = "5.00",
            total = "30.50",
            customerNote = "",
            billing = Billing.Empty,
            shipping = Shipping.Empty,
            paymentMethodTitle = "Credit Card",
            lineItems = emptyList(),
            shippingLines = emptyList()
        )
        
        assertEquals(5.0, order.discount, 0.01)
    }

    @Test
    fun testOrderDiscountInvalidString() {
        val order = Order(
            id = 1,
            number = "001",
            status = "processing",
            dateCreated = "",
            dateModified = "",
            discountTotal = "invalid",
            total = "30.50",
            customerNote = "",
            billing = Billing.Empty,
            shipping = Shipping.Empty,
            paymentMethodTitle = "",
            lineItems = emptyList(),
            shippingLines = emptyList()
        )
        
        assertEquals(0.0, order.discount, "Invalid discount string should return 0")
    }

    @Test
    fun testOrderDefault() {
        val order = Order.Default
        
        assertEquals(0, order.id)
        assertEquals("", order.number)
        assertEquals("on-hold", order.status)
        assertEquals("0", order.discountTotal)
        assertEquals("0", order.total)
        assertEquals(Billing.Empty, order.billing)
        assertEquals(Shipping.Empty, order.shipping)
        assertTrue(order.lineItems.isEmpty())
        assertTrue(order.shippingLines.isEmpty())
    }

    @Test
    fun testOrderJsonDecoding() {
        val jsonStr = """
        {
            "id": 12345,
            "number": "12345",
            "status": "processing",
            "date_created": "2024-01-15T10:30:00",
            "date_modified": "2024-01-15T10:35:00",
            "discount_total": "10.00",
            "total": "90.00",
            "customer_note": "Please deliver ASAP",
            "billing": {
                "first_name": "John",
                "last_name": "Doe",
                "country": "AU",
                "address_1": "123 Main St",
                "city": "Sydney",
                "postcode": "2000",
                "state": "NSW",
                "email": "john@example.com",
                "phone": "0412345678",
                "company": ""
            },
            "shipping": {
                "first_name": "John",
                "last_name": "Doe",
                "company": "",
                "country": "AU",
                "address_1": "123 Main St",
                "phone": "0412345678",
                "city": "Sydney",
                "postcode": "2000",
                "state": "NSW"
            },
            "payment_method_title": "Credit Card",
            "line_items": [
                {
                    "id": 1,
                    "name": "Product A",
                    "product_id": 100,
                    "quantity": 2,
                    "subtotal": "50.00",
                    "total": "50.00",
                    "price": 25.0
                }
            ],
            "shipping_lines": [],
            "payment_url": "https://example.com/pay",
            "order_key": "wc_order_abc123"
        }
        """
        
        val order = json.decodeFromString<Order>(jsonStr)
        
        assertEquals(12345, order.id)
        assertEquals("12345", order.number)
        assertEquals("processing", order.status)
        assertEquals(10.0, order.discount, 0.01)
        assertEquals("Please deliver ASAP", order.customerNote)
        assertEquals("John", order.billing.firstName)
        assertEquals("Credit Card", order.paymentMethodTitle)
        assertEquals(1, order.lineItems.size)
        assertEquals("Product A", order.lineItems[0].name)
        assertEquals("https://example.com/pay", order.paymentURL)
        assertEquals("wc_order_abc123", order.orderKey)
    }

    @Test
    fun testLineItemDefault() {
        val lineItem = LineItem.Default
        
        assertEquals(0, lineItem.id)
        assertEquals("", lineItem.name)
        assertEquals(0, lineItem.productId)
        assertEquals(0, lineItem.quantity)
        assertEquals("0", lineItem.subtotal)
        assertEquals("0", lineItem.total)
        assertEquals(0.0, lineItem.price)
    }

    private fun assertTrue(condition: Boolean, message: String = "") {
        kotlin.test.assertTrue(condition, message)
    }
}

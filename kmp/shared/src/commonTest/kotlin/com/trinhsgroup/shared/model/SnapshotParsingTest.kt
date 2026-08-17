package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/**
 * Snapshot-based parsing tests that verify model deserialization
 * matches expected iOS behavior.
 * 
 * These fixtures represent real WooCommerce API responses.
 */
class SnapshotParsingTest {
    
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
    }
    
    // region User Parsing
    
    @Test
    fun `parse user response with billing and shipping`() {
        val userJson = """
        {
          "id": 123,
          "first_name": "Test",
          "last_name": "User",
          "email": "test@example.com",
          "username": "testuser",
          "billing": {
            "first_name": "Test",
            "last_name": "User",
            "company": "",
            "address_1": "123 Test Street",
            "city": "Sydney",
            "state": "NSW",
            "postcode": "2000",
            "country": "AU",
            "email": "test@example.com",
            "phone": "0412345678"
          },
          "shipping": {
            "first_name": "Test",
            "last_name": "User",
            "company": "",
            "address_1": "123 Test Street",
            "city": "Sydney",
            "state": "NSW",
            "postcode": "2000",
            "country": "AU"
          }
        }
        """.trimIndent()
        
        val user = json.decodeFromString<User>(userJson)
        
        assertEquals(123, user.id)
        assertEquals("Test", user.firstName)
        assertEquals("User", user.lastName)
        assertEquals("test@example.com", user.email)
        assertEquals("testuser", user.username)
        
        // Billing
        assertEquals("Test", user.billing.firstName)
        assertEquals("Sydney", user.billing.city)
        assertEquals("NSW", user.billing.state)
        assertEquals("2000", user.billing.postcode)
        assertEquals("0412345678", user.billing.phone)
        
        // Shipping
        assertEquals("123 Test Street", user.shipping.address1)
    }
    
    // endregion
    
    // region Product Parsing
    
    @Test
    fun `parse product response with categories and images`() {
        val productJson = """
        {
          "id": 456,
          "name": "Pad Thai",
          "slug": "pad-thai",
          "permalink": "https://trinhskitchen.com.au/product/pad-thai/",
          "date_created": "2024-01-15T10:00:00",
          "date_modified": "2024-06-01T12:30:00",
          "type": "simple",
          "status": "publish",
          "featured": true,
          "catalog_visibility": "visible",
          "description": "<p>Traditional Thai stir-fried rice noodles.</p>",
          "short_description": "Classic Pad Thai",
          "sku": "PT001",
          "price": "18.50",
          "regular_price": "18.50",
          "sale_price": "",
          "on_sale": false,
          "purchasable": true,
          "total_sales": 250,
          "stock_status": "instock",
          "categories": [
            {
              "id": 15,
              "name": "Thai",
              "slug": "thai"
            }
          ],
          "images": [
            {
              "id": 789,
              "src": "https://trinhskitchen.com.au/wp-content/uploads/pad-thai.jpg",
              "name": "pad-thai",
              "alt": "Pad Thai"
            }
          ],
          "attributes": [
            {
              "id": 1,
              "name": "Spice Level",
              "position": 0,
              "visible": true,
              "variation": false,
              "options": ["Mild", "Medium", "Hot"]
            }
          ],
          "meta_data": [],
          "menu_order": 0
        }
        """.trimIndent()
        
        val product = json.decodeFromString<Product>(productJson)
        
        assertEquals(456, product.id)
        assertEquals("Pad Thai", product.name)
        assertEquals(18.5, product.price)
        assertEquals(18.5, product.regularPrice)
        assertEquals(0.0, product.salePrice) // Empty string becomes 0.0
        
        // Categories
        assertEquals(1, product.categories.size)
        assertEquals(15, product.categories.first().id)
        assertEquals("Thai", product.categories.first().name)
        
        // Images
        assertEquals(1, product.images.size)
        assertEquals("https://trinhskitchen.com.au/wp-content/uploads/pad-thai.jpg", product.images.first().src)
        
        // Attributes
        assertEquals(1, product.attributes.size)
        assertEquals("Spice Level", product.attributes.first().name)
        assertEquals(3, product.attributes.first().options.size)
    }
    
    @Test
    fun `parse product on sale with discount calculation`() {
        val productJson = """
        {
          "id": 457,
          "name": "Green Curry",
          "price": "16.00",
          "regular_price": "20.00",
          "sale_price": "16.00",
          "on_sale": true,
          "categories": [],
          "images": [],
          "attributes": [],
          "meta_data": []
        }
        """.trimIndent()
        
        val product = json.decodeFromString<Product>(productJson)
        
        assertEquals(457, product.id)
        assertEquals("Green Curry", product.name)
        assertEquals(16.0, product.price)
        assertEquals(20.0, product.regularPrice)
        assertEquals(16.0, product.salePrice)
        
        // Verify discount percentage calculation matches iOS
        // iOS: (20 - 16) / 20 * 100 = 20%
        val discountPercent = if (product.regularPrice > 0) {
            ((product.regularPrice - product.salePrice) / product.regularPrice * 100).toInt()
        } else 0
        assertEquals(20, discountPercent)
    }
    
    // endregion
    
    // region Order Parsing
    
    @Test
    fun `parse order response with line items`() {
        val orderJson = """
        {
          "id": 1001,
          "number": "1001",
          "status": "processing",
          "date_created": "2024-06-15T14:30:00",
          "date_modified": "2024-06-15T14:35:00",
          "discount_total": "2.00",
          "shipping_total": "0.00",
          "total": "52.50",
          "total_tax": "0.00",
          "customer_id": 123,
          "billing": {
            "first_name": "Test",
            "last_name": "User",
            "email": "test@example.com",
            "phone": "0412345678"
          },
          "shipping": {
            "first_name": "Test",
            "last_name": "User"
          },
          "payment_method": "stripe",
          "payment_method_title": "Credit Card (Stripe)",
          "customer_note": "Please add extra napkins",
          "line_items": [
            {
              "id": 101,
              "name": "Pad Thai",
              "product_id": 456,
              "quantity": 2,
              "subtotal": "37.00",
              "total": "37.00",
              "price": 18.5
            },
            {
              "id": 102,
              "name": "Green Curry",
              "product_id": 457,
              "quantity": 1,
              "subtotal": "16.00",
              "total": "16.00",
              "price": 16.0
            }
          ],
          "shipping_lines": [
            {
              "id": 201,
              "methodId": "flat_rate",
              "methodTitle": "Pickup",
              "total": "0.00"
            }
          ]
        }
        """.trimIndent()
        
        val order = json.decodeFromString<Order>(orderJson)
        
        assertEquals(1001, order.id)
        assertEquals("processing", order.status)
        assertEquals("52.50", order.total)
        assertEquals("Credit Card (Stripe)", order.paymentMethodTitle)
        
        // Line items
        assertEquals(2, order.lineItems.size)
        assertEquals("Pad Thai", order.lineItems.first().name)
        assertEquals(2, order.lineItems.first().quantity)
        assertEquals(18.5, order.lineItems.first().price)
        
        // Shipping lines
        assertEquals(1, order.shippingLines.size)
        assertEquals("Pickup", order.shippingLines.first().methodTitle)
        
        // Subtotal calculation
        // Subtotal is sum of line item subtotals: 37.00 + 16.00 = 53.00
        assertTrue(order.subtotal >= 52.99 && order.subtotal <= 53.01)
    }
    
    // endregion
    
    // region Category Parsing
    
    @Test
    fun `parse categories list response`() {
        val categoriesJson = """
        [
          {
            "id": 15,
            "name": "Thai",
            "image": {
              "id": 801,
              "src": "https://trinhskitchen.com.au/wp-content/uploads/thai-category.jpg"
            }
          },
          {
            "id": 16,
            "name": "Vietnamese",
            "image": {
              "id": 802,
              "src": "https://trinhskitchen.com.au/wp-content/uploads/vietnamese-category.jpg"
            }
          },
          {
            "id": 17,
            "name": "Japanese",
            "image": null
          }
        ]
        """.trimIndent()
        
        val categories = json.decodeFromString<List<Category>>(categoriesJson)
        
        assertEquals(3, categories.size)
        
        // First category with full image
        assertEquals(15, categories[0].id)
        assertEquals("Thai", categories[0].name)
        assertNotNull(categories[0].image)
        assertEquals("https://trinhskitchen.com.au/wp-content/uploads/thai-category.jpg", categories[0].image?.src)
        
        // Third category with null image
        assertEquals(17, categories[2].id)
        assertEquals("Japanese", categories[2].name)
        assertEquals(null, categories[2].image)
    }
    
    // endregion
    
    // region Payment Parsing
    
    @Test
    fun `parse payment methods response filtering enabled`() {
        val paymentsJson = """
        [
          {
            "id": "stripe",
            "title": "Credit Card (Stripe)",
            "description": "Pay with your credit or debit card via Stripe.",
            "order": 0,
            "enabled": true
          },
          {
            "id": "cod",
            "title": "Pay on Pickup",
            "description": "Pay when you collect your order.",
            "order": 1,
            "enabled": true
          },
          {
            "id": "bacs",
            "title": "Bank Transfer",
            "description": "Direct bank transfer.",
            "order": 2,
            "enabled": false
          }
        ]
        """.trimIndent()
        
        val payments = json.decodeFromString<List<Payment>>(paymentsJson)
        
        assertEquals(3, payments.size)
        
        // Filter to enabled only (matches iOS MainServices.onFetchPaymentMethods)
        val enabledPayments = payments.filter { it.enabled }
        assertEquals(2, enabledPayments.size)
        assertEquals("stripe", enabledPayments[0].id)
        assertEquals("cod", enabledPayments[1].id)
    }
    
    // endregion
    
    // region Stripe Payment Intent
    
    @Test
    fun `parse stripe payment intent response`() {
        val intentJson = """
        {
          "payment_intent": "pi_3O1234567890abcdefghijk",
          "customer": "cus_ABC123DEF456",
          "ephemeral_key": "ek_test_YWNjdF8xSGdWWWNIbHNEMXBzaENZ",
          "publishable_key": "pk_test_51HgVYcHlsD1pshCY0000000"
        }
        """.trimIndent()
        
        val response = json.decodeFromString<StripePaymentIntentResponse>(intentJson)
        
        assertEquals("pi_3O1234567890abcdefghijk", response.paymentIntent)
        assertEquals("cus_ABC123DEF456", response.customer)
        assertEquals("ek_test_YWNjdF8xSGdWWWNIbHNEMXBzaENZ", response.ephemeralKey)
        assertEquals("pk_test_51HgVYcHlsD1pshCY0000000", response.publishableKey)
        assertTrue(response.isValid)
    }
    
    @Test
    fun `stripe payment intent invalid when missing payment_intent`() {
        val intentJson = """
        {
          "customer": "cus_ABC123DEF456",
          "publishable_key": "pk_test_51HgVYcHlsD1pshCY0000000"
        }
        """.trimIndent()
        
        val response = json.decodeFromString<StripePaymentIntentResponse>(intentJson)
        
        assertEquals(null, response.paymentIntent)
        assertEquals(false, response.isValid)
    }
    
    // endregion
    
    // region Coupons/Vouchers
    
    @Test
    fun `parse WC coupon response and check validity`() {
        val couponJson = """
        {
          "id": 501,
          "code": "rw123-voucher10",
          "amount": "10.00",
          "status": "publish",
          "date_created": "2024-01-01T00:00:00",
          "date_expires": "2025-12-31T23:59:59",
          "discount_type": "fixed_cart",
          "description": "10 AUD reward voucher",
          "usage_count": 0,
          "usage_limit": 1,
          "individual_use": true,
          "minimum_amount": "0.00",
          "maximum_amount": "0.00",
          "email_restrictions": [],
          "used_by": []
        }
        """.trimIndent()
        
        val coupon = json.decodeFromString<WCCouponResponse>(couponJson)
        
        assertEquals(501, coupon.id)
        assertEquals("rw123-voucher10", coupon.code)
        assertEquals("10.00", coupon.amount)
        assertEquals("fixed_cart", coupon.discountType)
        assertEquals(0, coupon.usageCount)
        assertEquals(1, coupon.usageLimit)
        
        // Verify this is a user voucher (code starts with rw)
        assertTrue(coupon.code.lowercase().startsWith("rw"))
    }
    
    // endregion
}

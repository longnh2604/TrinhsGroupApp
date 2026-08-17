package com.trinhsgroup.shared.model

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Unit tests for Payment model.
 * Tests Int-or-String decoding for order field and fallback behavior.
 */
class PaymentTest {

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        explicitNulls = false
    }

    @Test
    fun testPaymentOrderDecodingFromInt() {
        val jsonStr = """
        {
            "id": "bacs",
            "title": "Direct Bank Transfer",
            "description": "Make payment directly",
            "enabled": true,
            "order": 1,
            "method_title": "Bank Transfer",
            "method_description": "Pay via bank"
        }
        """
        
        val payment = json.decodeFromString<Payment>(jsonStr)
        
        assertEquals("bacs", payment.id)
        assertEquals("Direct Bank Transfer", payment.title)
        assertEquals(true, payment.enabled)
        assertEquals(1, payment.order)
        assertEquals("Bank Transfer", payment.methodTitle)
    }

    @Test
    fun testPaymentOrderDecodingFromString() {
        val jsonStr = """
        {
            "id": "stripe",
            "title": "Credit Card (Stripe)",
            "description": "Pay with your credit card",
            "enabled": true,
            "order": "2",
            "method_title": "Stripe",
            "method_description": "Stripe payment gateway"
        }
        """
        
        val payment = json.decodeFromString<Payment>(jsonStr)
        
        assertEquals("stripe", payment.id)
        assertEquals(2, payment.order, "String '2' should be parsed as Int 2")
    }

    @Test
    fun testPaymentOrderInvalidValueFallback() {
        val jsonStr = """
        {
            "id": "cod",
            "title": "Cash on Delivery",
            "description": "",
            "enabled": false,
            "order": "invalid",
            "method_title": "",
            "method_description": ""
        }
        """
        
        val payment = json.decodeFromString<Payment>(jsonStr)
        
        assertEquals("cod", payment.id)
        assertEquals(0, payment.order, "Invalid order value should fallback to 0")
    }

    @Test
    fun testPaymentWithMissingOptionalFields() {
        val jsonStr = """
        {
            "id": "paypal",
            "enabled": true,
            "order": 3
        }
        """
        
        val payment = json.decodeFromString<Payment>(jsonStr)
        
        assertEquals("paypal", payment.id)
        assertEquals("", payment.title)
        assertEquals("", payment.description)
        assertEquals(true, payment.enabled)
        assertEquals(3, payment.order)
    }

    @Test
    fun testPaymentDisplayTitle() {
        val payment1 = Payment(
            id = "test",
            title = "Title",
            methodTitle = "Method Title"
        )
        assertEquals("Method Title", payment1.displayTitle)
        
        val payment2 = Payment(
            id = "test",
            title = "Title",
            methodTitle = ""
        )
        assertEquals("Title", payment2.displayTitle)
    }

    @Test
    fun testPaymentDisplayDescription() {
        val payment1 = Payment(
            id = "test",
            description = "Desc",
            methodDescription = "Method Desc"
        )
        assertEquals("Method Desc", payment1.displayDescription)
        
        val payment2 = Payment(
            id = "test",
            description = "Desc",
            methodDescription = ""
        )
        assertEquals("Desc", payment2.displayDescription)
    }

    @Test
    fun testSettingDecoding() {
        val jsonStr = """
        {
            "instructions": {
                "value": "Please pay within 7 days"
            }
        }
        """
        
        val setting = json.decodeFromString<Setting>(jsonStr)
        
        assertEquals("Please pay within 7 days", setting.instructions.value)
    }
}

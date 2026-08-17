package com.trinhsgroup.shared.service

import com.trinhsgroup.shared.model.AnyCodableValue
import com.trinhsgroup.shared.model.Billing
import com.trinhsgroup.shared.model.ProductMetaData
import com.trinhsgroup.shared.model.ProductOrder
import com.trinhsgroup.shared.model.User
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Pins the JSON sent to POST /wp-json/trinh-app/v1/me/orders.
 *
 * This is the one payload where a silent change bills the customer the wrong amount, or
 * files the order against the wrong account, so it is asserted against the real builder
 * rather than a hand-written copy of it.
 */
class OrderCreationPayloadTest {

    private val service = MainService()

    private val user = User(
        id = 42,
        email = "account@example.com",
        firstName = "Account",
        lastName = "Holder",
        billing = Billing(
            firstName = "Test",
            lastName = "User",
            country = "AU",
            address1 = "123 Test Street",
            city = "Sydney",
            state = "NSW",
            postcode = "2000",
            email = "billing@example.com",
            phone = "0412345678"
        )
    )

    private val productOrders = listOf(
        ProductOrder(
            id = 0,
            productId = 456,
            name = "Pad Thai",
            quantity = 2,
            subtotal = "",
            total = 37.00,
            price = 18.50,
            metaData = listOf(
                ProductMetaData(id = 1, key = "_note", value = AnyCodableValue.StringValue("No chilli"))
            )
        )
    )

    private fun payload(couponCode: String? = null) = service.buildOrderJson(
        user = user,
        paymentMethod = "stripe",
        paymentMethodTitle = "Credit Card",
        customerNote = "",
        status = "pending",
        productOrders = productOrders,
        pickupDateTime = "2026-06-15 18:30:00",
        couponCode = couponCode
    )

    /**
     * The server forces both from the JWT. Sending them would let a tampered request file an
     * order against another account, or mark it paid without paying.
     */
    @Test
    fun `payload omits customer_id and set_paid`() {
        val json = payload()
        assertNull(json["customer_id"])
        assertNull(json["set_paid"])
    }

    /**
     * The 5% cash-on-pickup discount is a gateway fee configured on the website. The app
     * withdrew its own copy of that arithmetic; sending prices would re-open the gap.
     */
    @Test
    fun `payload sends no prices and no fee lines`() {
        val json = payload()
        assertNull(json["fee_lines"])

        val lineItem = json["line_items"]!!.jsonArray.first().jsonObject
        assertNull(lineItem["price"])
        assertNull(lineItem["total"])
        assertNull(lineItem["subtotal"])
    }

    @Test
    fun `line items carry product, quantity and meta only`() {
        val lineItem = payload()["line_items"]!!.jsonArray.first().jsonObject

        assertEquals(456, lineItem["product_id"]?.jsonPrimitive?.content?.toInt())
        assertEquals(2, lineItem["quantity"]?.jsonPrimitive?.content?.toInt())

        val meta = lineItem["meta_data"]!!.jsonArray.first().jsonObject
        assertEquals("_note", meta["key"]?.jsonPrimitive?.content)
        assertEquals("No chilli", meta["value"]?.jsonPrimitive?.content)
    }

    @Test
    fun `payload includes billing and order fields`() {
        val json = payload()

        assertEquals("stripe", json["payment_method"]?.jsonPrimitive?.content)
        assertEquals("Credit Card", json["payment_method_title"]?.jsonPrimitive?.content)
        assertEquals("pending", json["status"]?.jsonPrimitive?.content)

        val billing = json["billing"]!!.jsonObject
        assertEquals("Test", billing["first_name"]?.jsonPrimitive?.content)
        assertEquals("User", billing["last_name"]?.jsonPrimitive?.content)
        assertEquals("Sydney", billing["city"]?.jsonPrimitive?.content)
        assertEquals("NSW", billing["state"]?.jsonPrimitive?.content)
        assertEquals("2000", billing["postcode"]?.jsonPrimitive?.content)
        assertEquals("AU", billing["country"]?.jsonPrimitive?.content)
        assertEquals("billing@example.com", billing["email"]?.jsonPrimitive?.content)
        assertEquals("0412345678", billing["phone"]?.jsonPrimitive?.content)
    }

    /** An order with no way to contact the customer is worse than a wrong-looking name. */
    @Test
    fun `billing falls back to the account when the address is blank`() {
        val json = service.buildOrderJson(
            user = User(id = 42, email = "account@example.com", firstName = "Account", lastName = "Holder"),
            paymentMethod = "cod",
            paymentMethodTitle = "Cash on pickup",
            customerNote = "",
            status = "on-hold",
            productOrders = productOrders,
            pickupDateTime = "2026-06-15 18:30:00",
            couponCode = null
        )

        val billing = json["billing"]!!.jsonObject
        assertEquals("Account", billing["first_name"]?.jsonPrimitive?.content)
        assertEquals("Holder", billing["last_name"]?.jsonPrimitive?.content)
        assertEquals("account@example.com", billing["email"]?.jsonPrimitive?.content)
        assertEquals("AU", billing["country"]?.jsonPrimitive?.content)
    }

    @Test
    fun `pickup datetime rides in order meta`() {
        val meta = payload()["meta_data"]!!.jsonArray.first().jsonObject
        assertEquals("pickup_datetime", meta["key"]?.jsonPrimitive?.content)
        assertEquals("2026-06-15 18:30:00", meta["value"]?.jsonPrimitive?.content)
    }

    @Test
    fun `coupon lines appear only when a voucher was chosen`() {
        assertNull(payload()["coupon_lines"])

        val withVoucher = payload(couponCode = "rw123-voucher10")["coupon_lines"]!!.jsonArray
        assertEquals(1, withVoucher.size)
        assertEquals("rw123-voucher10", withVoucher.first().jsonObject["code"]?.jsonPrimitive?.content)
    }

    @Test
    fun `order status follows the payment method`() {
        // iOS behaviour: stripe waits for payment, everything else goes straight to the kitchen queue
        assertEquals("pending", payload()["status"]?.jsonPrimitive?.content)
    }

    @Test
    fun `payload never mentions a discount of its own`() {
        val text = payload().toString()
        assertFalse(text.contains("fee_lines"), "the 5% belongs to the server now")
        assertTrue(text.contains("line_items"))
    }
}

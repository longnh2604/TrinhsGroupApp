package com.trinhsgroup.shared.model

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The basket → line items mapping, which both the quote and the order are built from.
 *
 * This used to live in CheckoutScreen and silently dropped addOnChoices, so every basket was
 * quoted and charged as if no add-on had been picked. Pinned here.
 */
class ProductOrderMappingTest {

    @Test
    fun `chosen add-ons survive the mapping`() {
        val choices = listOf(
            AddOnChoice(submitKey = "5-0", submitValue = "1", label = "Beef", price = 3.0)
        )
        val cart = listOf(
            Product(id = 42, name = "Family Trio", quantity = 2, regularPrice = 11.5, addOnChoices = choices)
        )

        val line = cart.toProductOrders().single()

        assertEquals(choices, line.addOnChoices)
        assertEquals(42, line.productId)
        assertEquals(2, line.quantity)
    }

    @Test
    fun `the kitchen note survives the mapping`() {
        val note = ProductMetaData(0, "_note", AnyCodableValue.StringValue("No chilli"))
        val cart = listOf(Product(id = 1, name = "Pho", quantity = 1, metaData = listOf(note)))

        assertEquals(listOf(note), cart.toProductOrders().single().metaData)
    }
}

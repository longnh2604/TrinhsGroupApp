package com.trinhsgroup.shared.service

import com.trinhsgroup.shared.model.Billing
import com.trinhsgroup.shared.model.LineItem
import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.model.Shipping
import com.trinhsgroup.shared.util.DateTimeUtils
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * Which order a timed-out submission is allowed to claim.
 *
 * The store creating an order and then answering too slowly is the case this exists for: the
 * app must find that order rather than tell the customer to try again, and it must never
 * hand back an older one — a wrong match shows someone the wrong basket, and no match at all
 * puts a duplicate in the kitchen.
 */
class TimedOutOrderRecoveryTest {

    private val service = MainService()

    /** Sydney time, because that is what WooCommerce writes into `date_created`. */
    private val now = DateTimeUtils.storeTimestampEpochSeconds("2026-08-21T18:30:00")!!

    private fun order(
        id: Int,
        status: String = "on-hold",
        createdAt: String = "2026-08-21T18:29:30",
        items: Int = 2
    ) = Order(
        id = id,
        number = id.toString(),
        status = status,
        dateCreated = createdAt,
        dateModified = createdAt,
        discountTotal = "0",
        total = "35.50",
        customerNote = "",
        billing = Billing.Empty,
        shipping = Shipping.Empty,
        paymentMethodTitle = "Cash",
        lineItems = (1..items).map {
            LineItem(id = it, name = "Item $it", productId = it, quantity = 1, subtotal = "10", total = "10", price = 10.0)
        },
        shippingLines = emptyList()
    )

    @Test
    fun `the order the store just created is claimed`() {
        val found = service.matchTimedOutOrder(listOf(order(id = 101)), itemCount = 2, nowEpochSeconds = now)

        assertEquals(101, found?.id)
    }

    @Test
    fun `the newest match wins`() {
        val orders = listOf(
            order(id = 101, createdAt = "2026-08-21T18:28:00"),
            order(id = 102, createdAt = "2026-08-21T18:29:50")
        )

        assertEquals(102, service.matchTimedOutOrder(orders, itemCount = 2, nowEpochSeconds = now)?.id)
    }

    @Test
    fun `an order from before this checkout is left alone`() {
        val orders = listOf(order(id = 101, createdAt = "2026-08-21T17:00:00"))

        assertNull(service.matchTimedOutOrder(orders, itemCount = 2, nowEpochSeconds = now))
    }

    @Test
    fun `a different basket is not this submission`() {
        val orders = listOf(order(id = 101, items = 3))

        assertNull(service.matchTimedOutOrder(orders, itemCount = 2, nowEpochSeconds = now))
    }

    /** Anything past the kitchen was placed earlier: create only ever yields pending or on-hold. */
    @Test
    fun `an order already being cooked is not this submission`() {
        val orders = listOf(order(id = 101, status = "processing"))

        assertNull(service.matchTimedOutOrder(orders, itemCount = 2, nowEpochSeconds = now))
    }

    /** The store's clock running a minute ahead of the phone's must not lose the order. */
    @Test
    fun `a timestamp slightly in the future still matches`() {
        val orders = listOf(order(id = 101, createdAt = "2026-08-21T18:30:30"))

        assertEquals(101, service.matchTimedOutOrder(orders, itemCount = 2, nowEpochSeconds = now)?.id)
    }

    @Test
    fun `nothing to claim when the store has no such order`() {
        assertNull(service.matchTimedOutOrder(emptyList(), itemCount = 2, nowEpochSeconds = now))
    }
}

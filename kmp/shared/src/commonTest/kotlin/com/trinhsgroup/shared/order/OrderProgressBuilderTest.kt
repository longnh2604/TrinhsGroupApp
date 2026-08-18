package com.trinhsgroup.shared.order

import com.trinhsgroup.shared.model.Billing
import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.model.OrderStatusHistory
import com.trinhsgroup.shared.model.OrderTimelineEvent
import com.trinhsgroup.shared.model.Shipping
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The progress rail's arithmetic. Pure, so it is asserted directly rather than through a screen.
 *
 * The interesting cases are the ones a happy-path reading misses: an order cancelled after it
 * started cooking must not show "Ready for Pickup" as merely pending.
 */
class OrderProgressBuilderTest {

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    private fun events(vararg pairs: Pair<String, String?>) =
        pairs.map { OrderTimelineEvent(it.first, it.second) }

    @Test
    fun `a normal order marks the stage it sits on as current`() {
        val steps = OrderProgressBuilder.steps(
            status = "processing",
            events = events("placed" to "1 Aug, 6:00 PM", "on-hold" to "1 Aug, 6:01 PM", "processing" to "1 Aug, 6:05 PM")
        )

        assertEquals(4, steps.size)
        assertEquals(OrderStepState.DONE, steps[0].state)
        assertEquals(OrderStepState.DONE, steps[1].state)
        assertEquals(OrderStepState.CURRENT, steps[2].state)
        assertEquals(OrderStepState.UPCOMING, steps[3].state)
        assertEquals("In Kitchen", steps[2].title)
        assertEquals("1 Aug, 6:05 PM", steps[2].timestamp)
    }

    @Test
    fun `the current node takes the hero colour so the two agree`() {
        val steps = OrderProgressBuilder.steps("processing", events("processing" to null))
        val current = steps.single { it.state == OrderStepState.CURRENT }

        assertEquals(OrderStatusPresentation.of("processing").tint, current.tint)
        // A completed node keeps its own stage colour.
        assertEquals(OrderStage.PLACED.tint, steps[0].tint)
    }

    /**
     * The case that motivates keeping the history at all: "cancelled" alone cannot say how far
     * the order got, so the rail stops where it actually stopped.
     */
    @Test
    fun `a cancelled order stops at the stage it reached`() {
        val steps = OrderProgressBuilder.steps(
            status = "cancelled",
            events = events(
                "placed" to "1 Aug, 6:00 PM",
                "on-hold" to "1 Aug, 6:01 PM",
                "processing" to "1 Aug, 6:05 PM",
                "cancelled" to "1 Aug, 6:20 PM"
            )
        )

        // Placed, Received, In Kitchen, then the terminal node — never "Ready for Pickup".
        assertEquals(4, steps.size)
        assertTrue(steps.none { it.title == "Ready for Pickup" })

        val terminal = steps.last()
        assertTrue(terminal.isTerminal)
        assertEquals("Order Cancelled", terminal.title)
        assertEquals("1 Aug, 6:20 PM", terminal.timestamp)
        assertEquals(StatusTint.FAILURE, terminal.tint)

        // Everything the order did reach reads as done, not as still to come.
        assertTrue(steps.dropLast(1).all { it.state == OrderStepState.DONE })
    }

    /**
     * With no history at all there is nothing to say how far the order got, so no stage can be
     * trimmed — the rail shows the four plus the terminal node. In practice the screen never
     * asks this: it falls back to the order's own dates, which is the case below.
     */
    @Test
    fun `a terminal order with no history cannot trim the rail`() {
        val steps = OrderProgressBuilder.steps("failed", emptyList())
        assertEquals(5, steps.size)
        assertTrue(steps.last().isTerminal)
        assertEquals("Payment Failed", steps.last().title)
    }

    /** The realistic terminal case: fallback dates place it, and the rail trims to that. */
    @Test
    fun `a failed order falls back to its own dates and trims`() {
        val order = Order.Default.copy(
            status = "failed",
            dateCreated = "2026-08-01T08:00:00",
            dateModified = "2026-08-01T08:02:00"
        )

        val steps = OrderProgressBuilder.steps(
            status = order.status,
            events = OrderProgressBuilder.fallbackEvents(order)
        )

        // Placed is as far as it got, so only that stage and the terminal node remain.
        assertEquals(2, steps.size)
        assertEquals("Order Placed", steps.first().title)
        assertTrue(steps.last().isTerminal)
    }

    @Test
    fun `the earliest timestamp wins when a stage repeats`() {
        val steps = OrderProgressBuilder.steps(
            status = "completed",
            events = events(
                "placed" to "1 Aug, 6:00 PM",
                "on-hold" to "1 Aug, 6:01 PM",
                "on-hold" to "1 Aug, 6:30 PM",
                "completed" to "1 Aug, 6:45 PM"
            )
        )
        assertEquals("1 Aug, 6:01 PM", steps[1].timestamp)
    }

    /** pending and placed share a stage: an unpaid order is placed but not yet confirmed. */
    @Test
    fun `pending sits in the placed stage`() {
        assertEquals(OrderStage.PLACED, OrderStage.of("pending"))
        assertEquals(OrderStage.PLACED, OrderStage.of("placed"))
        assertNull(OrderStage.of("cancelled"))
        assertNull(OrderStage.of("something-custom"))
    }

    @Test
    fun `an unmodelled status shows its slug rather than guessing`() {
        val presentation = OrderStatusPresentation.of("awaiting-pickup-window")
        assertEquals("Awaiting Pickup Window", presentation.title)
        assertEquals("", presentation.subtitle)
        assertTrue(!presentation.isTerminal)
    }

    @Test
    fun `fallback events use the order's own dates`() {
        val order = Order.Default.copy(
            status = "processing",
            dateCreated = "2026-08-01T08:00:00",
            dateModified = "2026-08-01T08:05:00"
        )

        val fallback = OrderProgressBuilder.fallbackEvents(order)
        assertEquals(listOf("placed", "processing"), fallback.map { it.status })
        assertTrue(fallback.all { it.displayTime != null })
    }

    @Test
    fun `decodes the history payload and formats Sydney time`() {
        val body = """
        {"order_id":11710,"status":"completed","history":[
          {"status":"placed","at":"2026-07-28T18:35:10","at_gmt":"2026-07-28T08:35:10"},
          {"status":"completed","at":"2026-07-28T19:02:00","at_gmt":"2026-07-28T09:02:00"}]}
        """.trimIndent()

        val history = json.decodeFromString<OrderStatusHistory>(body)
        val timeline = history.timelineEvents

        assertEquals(11710, history.orderId)
        assertEquals(listOf("placed", "completed"), timeline.map { it.status })
        // 08:35 UTC is 18:35 in Sydney in July (UTC+10).
        assertEquals("28 Jul, 6:35 PM", timeline.first().displayTime)
        assertEquals("28 Jul, 7:02 PM", timeline.last().displayTime)
    }

    @Test
    fun `an unparseable timestamp reads as absent rather than as a crash`() {
        val history = OrderStatusHistory(
            history = listOf(OrderStatusHistory.Entry(status = "placed", at = "not a date"))
        )
        assertNull(history.timelineEvents.single().displayTime)
    }
}

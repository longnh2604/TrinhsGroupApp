package com.trinhsgroup.shared.order

import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.model.OrderTimelineEvent
import com.trinhsgroup.shared.model.orderTimelineStamp

/**
 * Single source of truth for how a WooCommerce status is shown to a customer.
 * Mirrors Swift's OrderStatusPresentation.swift.
 *
 * Copy, icon, colour and stage all live here so the hero, the stepper, and anything added later
 * cannot drift into describing the same order differently. Colours are named rather than given
 * as values — the platform layer maps a [StatusTint] to its own palette.
 */

/**
 * The four steps of a normal order, in order.
 *
 * A stage is *reached* when a status implies it; statuses that end an order early have no stage.
 */
enum class OrderStage(val order: Int, val title: String) {
    PLACED(0, "Order Placed"),
    RECEIVED(1, "Order Received"),
    COOKING(2, "In Kitchen"),
    READY(3, "Ready for Pickup");

    /** Colour of this stage's node once it has been completed. */
    val tint: StatusTint
        get() = when (this) {
            PLACED, RECEIVED -> StatusTint.BRAND
            COOKING -> StatusTint.COOKING
            READY -> StatusTint.READY
        }

    val icon: StatusIcon
        get() = when (this) {
            PLACED -> StatusIcon.BAG
            RECEIVED -> StatusIcon.BELL
            COOKING -> StatusIcon.FLAME
            READY -> StatusIcon.SEAL
        }

    companion object {
        /**
         * The stage a status implies, or null for statuses that end an order early.
         *
         * `placed` is the synthetic status the server uses for the timestamp of order creation;
         * `pending` sits in the same stage — an unpaid order has been placed but not yet
         * confirmed by anyone.
         */
        fun of(status: String): OrderStage? = when (status) {
            "placed", "pending" -> PLACED
            "on-hold" -> RECEIVED
            "processing" -> COOKING
            "completed" -> READY
            else -> null
        }
    }
}

/**
 * Warm ramp that tracks the food: amber while waiting, orange in the kitchen, green when ready.
 * Named so the shared layer holds no platform colour type.
 */
enum class StatusTint { WAITING, BRAND, COOKING, READY, FAILURE }

enum class StatusIcon { BAG, BELL, FLAME, SEAL, CARD, CROSS, REFUND, WARNING, CLOCK }

/** What to show for one status: the customer's words, not WooCommerce's. */
data class OrderStatusPresentation(
    val title: String,
    val subtitle: String,
    val icon: StatusIcon,
    /** Name of a bundled Lottie animation to use instead of [icon], when one fits. */
    val lottieName: String?,
    val tint: StatusTint,
    /** True when the status ends the order — nothing further is coming. */
    val isTerminal: Boolean
) {
    companion object {
        fun of(status: String): OrderStatusPresentation = when (status) {
            "pending" -> OrderStatusPresentation(
                title = "Awaiting Payment",
                subtitle = "We'll start once your payment goes through.",
                icon = StatusIcon.CARD,
                lottieName = null,
                tint = StatusTint.WAITING,
                isTerminal = false
            )

            "on-hold" -> OrderStatusPresentation(
                title = "Order Received",
                subtitle = "We're confirming your order with the kitchen.",
                icon = StatusIcon.BELL,
                lottieName = "Order_onHold",
                tint = StatusTint.BRAND,
                isTerminal = false
            )

            "processing" -> OrderStatusPresentation(
                title = "In Kitchen",
                subtitle = "Our chefs are cooking your food right now.",
                icon = StatusIcon.FLAME,
                lottieName = "Order_processing",
                tint = StatusTint.COOKING,
                isTerminal = false
            )

            "completed" -> OrderStatusPresentation(
                title = "Ready for Pickup",
                subtitle = "Your order is ready — enjoy your meal!",
                icon = StatusIcon.SEAL,
                lottieName = "Order_ready",
                tint = StatusTint.READY,
                isTerminal = false
            )

            "cancelled" -> OrderStatusPresentation(
                title = "Order Cancelled",
                subtitle = "This order was cancelled.",
                icon = StatusIcon.CROSS,
                lottieName = null,
                tint = StatusTint.FAILURE,
                isTerminal = true
            )

            "refunded" -> OrderStatusPresentation(
                title = "Order Refunded",
                subtitle = "This order was refunded.",
                icon = StatusIcon.REFUND,
                lottieName = "Order_refunded",
                tint = StatusTint.WAITING,
                isTerminal = true
            )

            "failed" -> OrderStatusPresentation(
                title = "Payment Failed",
                subtitle = "The payment didn't go through.",
                icon = StatusIcon.WARNING,
                lottieName = "Order_failed",
                tint = StatusTint.FAILURE,
                isTerminal = true
            )

            else -> OrderStatusPresentation(
                // A status WooCommerce has but the app doesn't model — a custom one added in
                // wp-admin, say. Show the slug rather than pretending to know what it means.
                title = status.replace("-", " ").split(" ")
                    .joinToString(" ") { word -> word.replaceFirstChar { it.uppercase() } },
                subtitle = "",
                icon = StatusIcon.CLOCK,
                lottieName = null,
                tint = StatusTint.BRAND,
                isTerminal = false
            )
        }
    }
}

enum class OrderStepState { DONE, CURRENT, UPCOMING }

/** One row of the progress rail. */
data class OrderStep(
    val id: Int,
    val title: String,
    val icon: StatusIcon,
    val state: OrderStepState,
    /** Pre-formatted for display, or null when the step has no known timestamp. */
    val timestamp: String?,
    val tint: StatusTint,
    /** True for the appended cancelled / refunded / failed node. */
    val isTerminal: Boolean
)

/**
 * Reduces an order plus its status history into the rail's rows.
 *
 * Pure and free of UI state so it can be tested directly.
 */
object OrderProgressBuilder {

    /**
     * @param status the order's current WooCommerce status
     * @param events status history, oldest first. May be empty — see [fallbackEvents].
     */
    fun steps(status: String, events: List<OrderTimelineEvent>): List<OrderStep> {
        val presentation = OrderStatusPresentation.of(status)

        // How far the order actually got. For a terminal status this is what the happy path
        // cannot say: "cancelled" alone cannot tell you whether the food had started cooking.
        val reached = events.mapNotNull { OrderStage.of(it.status) }.maxByOrNull { it.order }

        // Earliest timestamp recorded for each stage.
        val stamps = mutableMapOf<OrderStage, String?>()
        for (event in events) {
            val stage = OrderStage.of(event.status) ?: continue
            if (!stamps.containsKey(stage)) stamps[stage] = event.displayTime
        }

        val current = if (presentation.isTerminal) null else OrderStage.of(status)

        val steps = OrderStage.entries.mapNotNull { stage ->
            // A terminal order's rail stops at the stage it reached; nodes it never got to are
            // replaced by the terminal node rather than shown as pending.
            if (presentation.isTerminal && reached != null && stage.order > reached.order) {
                return@mapNotNull null
            }

            val state = when {
                current == null -> OrderStepState.DONE // terminal: all it reached is behind it
                stage.order < current.order -> OrderStepState.DONE
                stage.order == current.order -> OrderStepState.CURRENT
                else -> OrderStepState.UPCOMING
            }

            OrderStep(
                id = stage.order,
                title = stage.title,
                icon = stage.icon,
                state = state,
                timestamp = stamps[stage],
                // The node the order sits on takes the hero's colour so the two agree;
                // completed nodes keep their own stage colour.
                tint = if (state == OrderStepState.CURRENT) presentation.tint else stage.tint,
                isTerminal = false
            )
        }.toMutableList()

        if (presentation.isTerminal) {
            steps.add(
                OrderStep(
                    id = OrderStage.entries.size,
                    title = presentation.title,
                    icon = presentation.icon,
                    state = OrderStepState.CURRENT,
                    timestamp = events.lastOrNull { it.status == status }?.displayTime,
                    tint = presentation.tint,
                    isTerminal = true
                )
            )
        }

        return steps
    }

    /**
     * Timeline to use when the history endpoint gave us nothing — the request failed, or the
     * order predates it.
     *
     * Shows creation time on the first step and last-modified on the current one.
     */
    fun fallbackEvents(order: Order): List<OrderTimelineEvent> {
        val events = mutableListOf<OrderTimelineEvent>()

        if (order.dateCreated.isNotEmpty()) {
            events.add(OrderTimelineEvent("placed", orderTimelineStamp(order.dateCreated)))
        }

        if (order.status != "placed" && order.dateModified.isNotEmpty()) {
            events.add(OrderTimelineEvent(order.status, orderTimelineStamp(order.dateModified)))
        }

        return events
    }
}

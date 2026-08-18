package com.trinhsgroup.shared.model

import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Wire type for GET /wp-json/trinh-app/v1/me/orders/{id}/history.
 * Mirrors Swift's OrderStatusHistory in OrderStatusHistoryModel.swift.
 *
 * Status timeline for one order, oldest entry first.
 */
@Serializable
data class OrderStatusHistory(
    @SerialName("order_id") val orderId: Int = 0,
    /** The order's current status, as the server sees it. */
    val status: String = "",
    val history: List<Entry> = emptyList()
) {
    @Serializable
    data class Entry(
        val status: String = "",
        /** Site-local time, matching the WooCommerce REST order payload's `date_created`. */
        val at: String = "",
        /** The same moment in UTC. Optional so an older server sending only `at` still decodes. */
        @SerialName("at_gmt") val atGmt: String? = null
    )

    /**
     * The timeline, formatted for the progress rail.
     *
     * Prefers `at_gmt`, which is unambiguous; falls back to `at` rather than showing a stage
     * with no time at all.
     */
    val timelineEvents: List<OrderTimelineEvent>
        get() = history.map { entry ->
            OrderTimelineEvent(
                status = entry.status,
                displayTime = orderTimelineStamp(entry.atGmt ?: entry.at)
            )
        }
}

/**
 * One status change, with its time already formatted for display.
 *
 * Deliberately not a date type: the fallback path has no `at_gmt` to offer, so the view layer
 * works in terms of "a status plus a string to print".
 */
data class OrderTimelineEvent(
    val status: String,
    val displayTime: String?
)

/**
 * A WordPress `Y-m-d\TH:i:s` timestamp rendered for the progress rail —
 * `"2026-07-28T08:35:10"` becomes `"28 Jul, 6:35 PM"`.
 *
 * Parsed as UTC, which is correct for the endpoint's `at_gmt`; the `at` fallback reproduces the
 * app's existing assumption rather than making one screen disagree with every other.
 */
fun orderTimelineStamp(raw: String): String? {
    val instant = try {
        Instant.parse(if (raw.endsWith("Z")) raw else "${raw}Z")
    } catch (_: Exception) {
        return null
    }

    val local = instant.toLocalDateTime(TimeZone.of("Australia/Sydney"))
    val month = listOf(
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    )[local.monthNumber - 1]

    val hour24 = local.hour
    val hour12 = when {
        hour24 == 0 -> 12
        hour24 > 12 -> hour24 - 12
        else -> hour24
    }
    val meridiem = if (hour24 < 12) "AM" else "PM"
    val minute = local.minute.toString().padStart(2, '0')

    return "${local.dayOfMonth} $month, $hour12:$minute $meridiem"
}

package com.trinhsgroup.shared.util

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDateTime
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toInstant
import kotlinx.datetime.toLocalDateTime

/**
 * Date and timezone utility functions.
 * Mirrors the Swift date parsing functions in Extensions.swift.
 */
object DateTimeUtils {

    private val SYDNEY_TIMEZONE = TimeZone.of("Australia/Sydney")
    private val UTC_TIMEZONE = TimeZone.UTC

    /**
     * Converts an ISO-like datetime string to Australia/Sydney time.
     * Mirrors Swift's String.toAustraliaDateTime() extension.
     *
     * @param dateString The input date string (e.g., "2025-09-22T03:04:03")
     * @param inputFormat Not used in Kotlin - we parse ISO format directly
     * @param outputFormat The output format pattern (default: "yyyy-MM-dd hh:mm:ss")
     * @return Formatted date string in Australia/Sydney timezone, or original string if parsing fails
     */
    fun toAustraliaDateTime(
        dateString: String,
        outputFormat: String = "yyyy-MM-dd hh:mm:ss"
    ): String {
        return try {
            // Parse as ISO datetime, assuming UTC if no timezone
            val instant = parseIsoDateTime(dateString) ?: return dateString
            
            // Convert to Sydney time
            val sydneyDateTime = instant.toLocalDateTime(SYDNEY_TIMEZONE)
            
            // Format output
            formatDateTime(sydneyDateTime, outputFormat)
        } catch (e: Exception) {
            dateString
        }
    }

    /**
     * Whether a WooCommerce timestamp falls on today's date in Australia/Sydney.
     * Mirrors the isSameAustralianDay check in Swift's MyOrdersView.
     *
     * The shop's day is what divides "today's orders" from history, so the comparison is made
     * in the shop's timezone rather than the device's — a customer travelling overseas should
     * still see today's pickup under Orders.
     *
     * An unparseable date reads as not-today: better to file it under history than to show it
     * as live.
     */
    fun isToday(dateString: String): Boolean {
        val instant = parseIsoDateTime(dateString) ?: return false
        val date = instant.toLocalDateTime(SYDNEY_TIMEZONE).date
        val today = Clock.System.now().toLocalDateTime(SYDNEY_TIMEZONE).date
        return date == today
    }

    /**
     * Converts a datetime string to a display format.
     * Mirrors Swift's String.toDate() extension.
     *
     * @param dateString The input date string
     * @return Formatted date string like "22 Sep 2025 14:30"
     */
    fun toDisplayDate(dateString: String): String {
        return try {
            val instant = parseIsoDateTime(dateString) ?: return dateString
            val localDateTime = instant.toLocalDateTime(TimeZone.currentSystemDefault())
            
            val day = localDateTime.dayOfMonth.toString().padStart(2, '0')
            val month = getMonthAbbreviation(localDateTime.monthNumber)
            val year = localDateTime.year
            val hour = localDateTime.hour.toString().padStart(2, '0')
            val minute = localDateTime.minute.toString().padStart(2, '0')
            
            "$day $month $year $hour:$minute"
        } catch (e: Exception) {
            dateString
        }
    }

    /**
     * Formats a pickup datetime for order creation.
     * Used in MainServices.onCreateOrder for pickup_datetime meta.
     *
     * @param dateString The selected pickup datetime
     * @return Formatted string for the API (yyyy-MM-dd HH:mm:ss)
     */
    fun formatPickupDateTime(dateString: String): String {
        return try {
            val instant = parseIsoDateTime(dateString) ?: return dateString
            val sydneyDateTime = instant.toLocalDateTime(SYDNEY_TIMEZONE)
            formatDateTime(sydneyDateTime, "yyyy-MM-dd HH:mm:ss")
        } catch (e: Exception) {
            dateString
        }
    }

    /**
     * Parses an ISO-8601 datetime string to Instant.
     * Handles both with and without timezone suffix.
     */
    private fun parseIsoDateTime(dateString: String): Instant? {
        if (dateString.isEmpty()) return null
        
        return try {
            // Try standard ISO-8601 format first
            Instant.parse(dateString)
        } catch (e: Exception) {
            // Try without timezone (assume UTC)
            try {
                val cleanString = dateString.replace(" ", "T")
                // Parse as LocalDateTime and convert to Instant assuming UTC
                val localDateTime = LocalDateTime.parse(cleanString)
                localDateTime.toInstant(UTC_TIMEZONE)
            } catch (e2: Exception) {
                // Try adding Z suffix
                try {
                    val normalized = if (dateString.endsWith("Z")) dateString
                    else "${dateString}Z"
                    Instant.parse(normalized)
                } catch (e3: Exception) {
                    null
                }
            }
        }
    }

    /**
     * A WooCommerce timestamp as epoch seconds.
     *
     * `date_created` carries no offset and is in the store's own timezone, so it is read as
     * Sydney time — reading it as UTC would put every order ten hours in the past.
     */
    fun storeTimestampEpochSeconds(dateString: String): Long? {
        if (dateString.isEmpty()) return null
        return try {
            LocalDateTime.parse(dateString.replace(" ", "T")).toInstant(SYDNEY_TIMEZONE).epochSeconds
        } catch (e: Exception) {
            parseIsoDateTime(dateString)?.epochSeconds
        }
    }

    /**
     * Formats a LocalDateTime according to a format pattern.
     * Supports common patterns used in the app.
     */
    private fun formatDateTime(dateTime: LocalDateTime, pattern: String): String {
        val year = dateTime.year.toString()
        val month = dateTime.monthNumber.toString().padStart(2, '0')
        val day = dateTime.dayOfMonth.toString().padStart(2, '0')
        val hour24 = dateTime.hour.toString().padStart(2, '0')
        val hour12 = ((dateTime.hour + 11) % 12 + 1).toString().padStart(2, '0')
        val minute = dateTime.minute.toString().padStart(2, '0')
        val second = dateTime.second.toString().padStart(2, '0')
        val amPm = if (dateTime.hour < 12) "AM" else "PM"
        
        return pattern
            .replace("yyyy", year)
            .replace("MM", month)
            .replace("dd", day)
            .replace("HH", hour24)
            .replace("hh", hour12)
            .replace("mm", minute)
            .replace("ss", second)
            .replace("a", amPm)
    }

    /**
     * Gets the 3-letter month abbreviation.
     */
    private fun getMonthAbbreviation(month: Int): String {
        return when (month) {
            1 -> "Jan"
            2 -> "Feb"
            3 -> "Mar"
            4 -> "Apr"
            5 -> "May"
            6 -> "Jun"
            7 -> "Jul"
            8 -> "Aug"
            9 -> "Sep"
            10 -> "Oct"
            11 -> "Nov"
            12 -> "Dec"
            else -> "???"
        }
    }
}

/**
 * Pickup slots still on offer today, as minutes from midnight.
 *
 * Mirrors PickupDateTimeView.swift: 30-minute blocks from 11:30 to the last start at 20:30,
 * the 15:00 hour closed, and nothing before the next half-hour boundary — a slot starting
 * exactly now is still offered, one that started a minute ago is not.
 *
 * @param nowMinutes current Sydney time as minutes from midnight
 */
fun availablePickupSlots(nowMinutes: Int): List<Int> {
    val remainder = nowMinutes % 30
    val cutoff = if (remainder == 0) nowMinutes else nowMinutes + (30 - remainder)
    return (11 * 60 + 30..20 * 60 + 30 step 30)
        .filter { it / 60 != 15 && it >= cutoff }
}

/**
 * Extension function for String to convert to Australia/Sydney datetime.
 * Mirrors Swift's String extension.
 */
fun String.toAustraliaDateTime(
    outputFormat: String = "yyyy-MM-dd hh:mm:ss"
): String = DateTimeUtils.toAustraliaDateTime(this, outputFormat)

/**
 * Extension function for String to convert to display date format.
 */
fun String.toDisplayDate(): String = DateTimeUtils.toDisplayDate(this)

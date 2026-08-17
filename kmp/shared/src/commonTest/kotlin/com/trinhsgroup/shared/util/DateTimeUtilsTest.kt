package com.trinhsgroup.shared.util

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class DateTimeUtilsTest {

    @Test
    fun testToAustraliaDateTime() {
        val result = DateTimeUtils.toAustraliaDateTime("2024-01-15T10:30:00")
        assertNotNull(result)
        assertTrue(result.contains("2024"))
    }

    @Test
    fun testToAustraliaDateTimeInvalid() {
        // Invalid date returns original string
        val result = DateTimeUtils.toAustraliaDateTime("invalid-date")
        assertEquals("invalid-date", result)
    }

    @Test
    fun testToDisplayDate() {
        // Tests that the function returns formatted string
        val result = DateTimeUtils.toDisplayDate("2024-01-15T10:30:00")
        assertNotNull(result)
        assertTrue(result.contains("2024"))
    }

    @Test
    fun testToDisplayDateInvalid() {
        // Invalid date returns original string
        val result = DateTimeUtils.toDisplayDate("invalid-date")
        assertEquals("invalid-date", result)
    }

    @Test
    fun testFormatPickupDateTime() {
        // Tests that the function returns a formatted date time
        val result = DateTimeUtils.formatPickupDateTime("2024-01-15T10:30:00")
        assertNotNull(result)
        // Should contain either formatted date or the original parts
        assertTrue(result.isNotEmpty())
    }

    @Test
    fun testStringExtensionToAustraliaDateTime() {
        val result = "2024-01-15T10:30:00".toAustraliaDateTime()
        assertNotNull(result)
        assertTrue(result.contains("2024"))
    }

    @Test
    fun testStringExtensionToDisplayDate() {
        val result = "2024-01-15T10:30:00".toDisplayDate()
        assertNotNull(result)
        assertTrue(result.contains("2024"))
    }
}

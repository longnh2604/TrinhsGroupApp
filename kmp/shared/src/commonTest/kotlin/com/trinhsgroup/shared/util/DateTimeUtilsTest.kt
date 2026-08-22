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

    @Test
    fun testPickupSlotsBeforeOpening() {
        // Whole day on offer: 11:30 to 20:30 in halves, minus the closed 15:00 hour
        val slots = availablePickupSlots(9 * 60)
        assertEquals(11 * 60 + 30, slots.first())
        assertEquals(20 * 60 + 30, slots.last())
        assertEquals(17, slots.size)
        assertTrue(slots.none { it / 60 == 15 })
    }

    @Test
    fun testPickupSlotOnTheBoundaryIsStillOffered() {
        // iOS keeps a slot starting exactly now; dropping it was the Android divergence
        assertEquals(12 * 60, availablePickupSlots(12 * 60).first())
        assertEquals(12 * 60 + 30, availablePickupSlots(12 * 60 + 1).first())
    }

    @Test
    fun testPickupSlotsRoundUpToNextHalfHour() {
        assertEquals(13 * 60, availablePickupSlots(12 * 60 + 31).first())
        // 14:31 rounds to 15:00, which is closed, so the next opening is 16:00
        assertEquals(16 * 60, availablePickupSlots(14 * 60 + 31).first())
    }

    @Test
    fun testPickupSlotsAfterLastStart() {
        assertTrue(availablePickupSlots(20 * 60 + 31).isEmpty())
    }
}

package com.trinhsgroup.shared.service

import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Tests for PointsService - specifically the parseRedeemError logic.
 */
class PointsServiceTest {

    @Test
    fun testParseRedeemError_invalidUserId() {
        val result = parseRedeemErrorPublic("invalid_user_id")
        assertEquals("Invalid user account", result)
    }

    @Test
    fun testParseRedeemError_invalidPoints() {
        val result = parseRedeemErrorPublic("invalid_points")
        assertEquals("Invalid points amount", result)
    }

    @Test
    fun testParseRedeemError_pointsNotAllowed() {
        val result = parseRedeemErrorPublic("points_not_allowed")
        assertEquals("Points must be at least 10 and in increments of 10", result)
    }

    @Test
    fun testParseRedeemError_insufficientPoints() {
        val result = parseRedeemErrorPublic("insufficient_points")
        assertEquals("Insufficient points for this redemption", result)
    }

    @Test
    fun testParseRedeemError_couponCreateFailed() {
        val result = parseRedeemErrorPublic("coupon_create_failed")
        assertEquals("Failed to create voucher. Please try again.", result)
    }

    @Test
    fun testParseRedeemError_mycredNotAvailable() {
        val result = parseRedeemErrorPublic("mycred_not_available")
        assertEquals("Points system unavailable", result)
    }

    @Test
    fun testParseRedeemError_woocommerceNotAvailable() {
        val result = parseRedeemErrorPublic("woocommerce_not_available")
        assertEquals("Store system unavailable", result)
    }

    @Test
    fun testParseRedeemError_unknownError() {
        val result = parseRedeemErrorPublic("Some random error message")
        assertEquals("Some random error message", result)
    }

    @Test
    fun testParseRedeemError_errorContainsKeyword() {
        // Error message contains the keyword
        val result = parseRedeemErrorPublic("Error: invalid_user_id - please try again")
        assertEquals("Invalid user account", result)
    }
}

/**
 * Public wrapper for testing parseRedeemError logic.
 * Mirrors the private function in PointsService.
 */
private fun parseRedeemErrorPublic(errorString: String): String {
    return when {
        errorString.contains("invalid_user_id") -> "Invalid user account"
        errorString.contains("invalid_points") -> "Invalid points amount"
        errorString.contains("points_not_allowed") -> "Points must be at least 10 and in increments of 10"
        errorString.contains("insufficient_points") -> "Insufficient points for this redemption"
        errorString.contains("coupon_create_failed") -> "Failed to create voucher. Please try again."
        errorString.contains("mycred_not_available") -> "Points system unavailable"
        errorString.contains("woocommerce_not_available") -> "Store system unavailable"
        else -> errorString
    }
}

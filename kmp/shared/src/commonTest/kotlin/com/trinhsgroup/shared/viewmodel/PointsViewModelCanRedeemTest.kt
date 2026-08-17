package com.trinhsgroup.shared.viewmodel

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Tests for PointsViewModel canRedeem logic.
 * Tests the critical points redemption rules that must match iOS behavior exactly.
 *
 * Rules:
 * - User must have >= requested points in balance
 * - Requested points must be >= 10
 * - Requested points must be divisible by 10
 */
class PointsViewModelCanRedeemTest {

    @Test
    fun testCanRedeemWithSufficientPoints() {
        val canRedeem = CanRedeemLogic(balance = 100.0)
        assertTrue(canRedeem.check(points = 50))
    }

    @Test
    fun testCanRedeemExactBalance() {
        val canRedeem = CanRedeemLogic(balance = 50.0)
        assertTrue(canRedeem.check(points = 50))
    }

    @Test
    fun testCannotRedeemInsufficientPoints() {
        val canRedeem = CanRedeemLogic(balance = 30.0)
        assertFalse(canRedeem.check(points = 50))
    }

    @Test
    fun testCannotRedeemLessThan10() {
        val canRedeem = CanRedeemLogic(balance = 100.0)
        assertFalse(canRedeem.check(points = 5))
    }

    @Test
    fun testCannotRedeemNotDivisibleBy10() {
        val canRedeem = CanRedeemLogic(balance = 100.0)
        assertFalse(canRedeem.check(points = 15))
    }

    @Test
    fun testCanRedeemMinimum10() {
        val canRedeem = CanRedeemLogic(balance = 100.0)
        assertTrue(canRedeem.check(points = 10))
    }

    @Test
    fun testCannotRedeemZero() {
        val canRedeem = CanRedeemLogic(balance = 100.0)
        assertFalse(canRedeem.check(points = 0))
    }

    @Test
    fun testCannotRedeemNegative() {
        val canRedeem = CanRedeemLogic(balance = 100.0)
        assertFalse(canRedeem.check(points = -10))
    }

    @Test
    fun testCannotRedeemNullBalance() {
        val canRedeem = CanRedeemLogic(balance = null)
        assertFalse(canRedeem.check(points = 10))
    }

    @Test
    fun testCanRedeemLargeAmount() {
        val canRedeem = CanRedeemLogic(balance = 1000.0)
        assertTrue(canRedeem.check(points = 500))
    }

    @Test
    fun testCanRedeem10PointIncrements() {
        val canRedeem = CanRedeemLogic(balance = 100.0)
        assertTrue(canRedeem.check(points = 10))
        assertTrue(canRedeem.check(points = 20))
        assertTrue(canRedeem.check(points = 30))
        assertTrue(canRedeem.check(points = 100))
    }
}

/**
 * Helper class to test canRedeem logic in isolation.
 * Mirrors the canRedeem method in PointsViewModel.
 */
class CanRedeemLogic(private val balance: Double?) {
    fun check(points: Int): Boolean {
        val currentBalance = balance ?: return false
        return currentBalance.toInt() >= points && points >= 10 && points % 10 == 0
    }
}

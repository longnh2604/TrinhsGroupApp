package com.trinhsgroup.shared.util

import kotlin.test.Test
import kotlin.test.assertEquals

class PriceFormattingTest {

    @Test
    fun testGetPriceFromDouble() {
        assertEquals("$10.00", PriceFormatting.getPrice(10.0))
        assertEquals("$10.50", PriceFormatting.getPrice(10.5))
        assertEquals("$1,000.00", PriceFormatting.getPrice(1000.0))
        assertEquals("$1,234.56", PriceFormatting.getPrice(1234.56))
    }

    @Test
    fun testGetPriceFromString() {
        assertEquals("$10.00", PriceFormatting.getPrice("10"))
        assertEquals("$10.50", PriceFormatting.getPrice("10.5"))
        assertEquals("$1,234.00", PriceFormatting.getPrice("1234"))
    }

    @Test
    fun testGetPriceFromInvalidString() {
        assertEquals("$0.00", PriceFormatting.getPrice(""))
        assertEquals("$0.00", PriceFormatting.getPrice("invalid"))
    }

    @Test
    fun testGetPriceAndCurrencySymbol_left() {
        assertEquals("$100.00", PriceFormatting.getPriceAndCurrencySymbol(100.0, "$", "left"))
    }

    @Test
    fun testGetPriceAndCurrencySymbol_right() {
        assertEquals("100.00€", PriceFormatting.getPriceAndCurrencySymbol(100.0, "€", "right"))
    }

    @Test
    fun testGetPriceAndCurrencySymbol_leftSpace() {
        assertEquals("$ 100.00", PriceFormatting.getPriceAndCurrencySymbol(100.0, "$", "left_space"))
    }

    @Test
    fun testGetPriceAndCurrencySymbol_rightSpace() {
        assertEquals("100.00 €", PriceFormatting.getPriceAndCurrencySymbol(100.0, "€", "right_space"))
    }

    @Test
    fun testGetDiscountPercentage() {
        // Note: Swift implementation has a bug: (100 * regular - sale) / regular
        // We preserve this for parity. With regular=100, sale=10:
        // (100 * 100 - 10) / 100 = 9990 / 100 = 99
        assertEquals("99% OFF", PriceFormatting.getDiscountPercentage(100.0, 10.0))
        assertEquals("99% OFF", PriceFormatting.getDiscountPercentage(100.0, 50.0))
        assertEquals("99% OFF", PriceFormatting.getDiscountPercentage(100.0, 100.0))
    }

    @Test
    fun testGetDiscountPercentageInvalidInputs() {
        assertEquals("0% OFF", PriceFormatting.getDiscountPercentage(0.0, 10.0))
        assertEquals("0% OFF", PriceFormatting.getDiscountPercentage(-1.0, 10.0))
    }
}

package com.trinhsgroup.shared.util

/**
 * Utility functions for formatting prices and currency.
 * Mirrors the Swift getPrice, getPriceAndCurrencySymbol, getDiscountPercentage functions in Constant.swift.
 */
object PriceFormatting {

    /**
     * Formats a double value as a price string with currency formatting.
     * Mirrors Swift's getPrice(value: Double) function.
     *
     * @param value The price value to format
     * @return Formatted price string with thousands separators and 2 decimal places
     */
    fun getPrice(value: Double): String {
        return formatCurrency(value)
    }

    /**
     * Formats a string value as a price string.
     * Mirrors Swift's getPrice(value: String) function.
     *
     * @param value The price value as a string
     * @return Formatted price string
     */
    fun getPrice(value: String): String {
        val doubleValue = value.toDoubleOrNull() ?: 0.0
        return formatCurrency(doubleValue)
    }

    /**
     * Formats a price with currency symbol based on position.
     * Mirrors Swift's getPriceAndCurrencySymbol function.
     *
     * @param price The price value
     * @param currency The currency symbol (e.g., "$", "AUD")
     * @param currencyPosition Position of currency: "left", "left_space", "right", "right_space"
     * @return Formatted price string with currency symbol
     */
    fun getPriceAndCurrencySymbol(
        price: Double,
        currency: String = "$",
        currencyPosition: String = "left"
    ): String {
        val priceString = formatDecimal(price)
        
        return when (currencyPosition) {
            "right" -> "$priceString$currency"
            "right_space" -> "$priceString $currency"
            "left" -> "$currency$priceString"
            else -> "$currency $priceString" // default is "left_space"
        }
    }

    /**
     * Calculates the discount percentage between regular and sale price.
     * Mirrors Swift's getDiscountPercentage function.
     *
     * Note: The Swift implementation has a bug - it calculates (100 * regular - sale) / regular
     * instead of ((regular - sale) / regular) * 100. We preserve this behavior for parity.
     *
     * @param regularPrice The original regular price
     * @param salePrice The discounted sale price
     * @return Formatted string like "25% OFF"
     */
    fun getDiscountPercentage(regularPrice: Double, salePrice: Double): String {
        if (regularPrice <= 0) return "0% OFF"
        // Note: This matches the Swift bug: (100 * regular - sale) / regular
        // Which is equivalent to: 100 - (sale / regular)
        // The correct formula would be: ((regular - sale) / regular) * 100
        val percentage = ((100 * regularPrice - salePrice) / regularPrice).toInt()
        return "$percentage% OFF"
    }

    /**
     * Formats a decimal number with 2 decimal places.
     * Uses period as decimal separator (Locale.US style).
     */
    private fun formatDecimal(value: Double): String {
        // Format with 2 decimal places, using period as decimal separator
        // Use rounding to avoid floating point precision issues
        val rounded = kotlin.math.round(value * 100) / 100
        val intPart = rounded.toLong()
        val fracPart = kotlin.math.round((rounded - intPart) * 100).toLong().let { 
            if (it < 0) -it else it 
        }
        
        // Format integer part with thousands separators
        val formattedIntPart = formatWithThousandsSeparator(intPart)
        
        return "$formattedIntPart.${fracPart.toString().padStart(2, '0')}"
    }

    /**
     * Formats a currency value with thousands separators and 2 decimal places.
     * Adds "$" prefix to match Swift's getPrice which uses .currency style.
     */
    private fun formatCurrency(value: Double): String {
        return "$${formatDecimal(value)}"
    }

    /**
     * Adds thousands separators to a long value.
     */
    private fun formatWithThousandsSeparator(value: Long): String {
        val absValue = if (value < 0) -value else value
        val str = absValue.toString()
        val result = StringBuilder()
        
        var count = 0
        for (i in str.indices.reversed()) {
            if (count > 0 && count % 3 == 0) {
                result.insert(0, ',')
            }
            result.insert(0, str[i])
            count++
        }
        
        return if (value < 0) "-$result" else result.toString()
    }
}

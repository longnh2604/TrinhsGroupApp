package com.trinhskitchen.app.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * App color palette.
 * Mirrors iOS Constants.AppColor values.
 */
object AppColors {
    // Primary colors
    val Primary = Color(0xFFE53935)      // Red - main brand color
    val PrimaryVariant = Color(0xFFC62828)
    val Secondary = Color(0xFFFF7043)    // Orange accent
    
    // Background colors
    val Background = Color(0xFFFAFAFA)
    val Surface = Color.White
    val SurfaceVariant = Color(0xFFF5F5F5)
    
    // Text colors
    val TextPrimary = Color(0xFF212121)
    val TextSecondary = Color(0xFF757575)
    val TextHint = Color(0xFFBDBDBD)
    
    // Status colors
    val Success = Color(0xFF4CAF50)
    val Warning = Color(0xFFFFC107)
    val Error = Color(0xFFF44336)
    val Info = Color(0xFF2196F3)
    
    // Tab bar
    val TabSelected = Primary
    val TabUnselected = Color(0xFF9E9E9E)
    
    // Divider
    val Divider = Color(0xFFE0E0E0)
    
    // Cart badge
    val Badge = Primary
    val BadgeText = Color.White
    
    // Price colors
    val RegularPrice = TextSecondary
    val SalePrice = Primary
    val DiscountBadge = Primary
}

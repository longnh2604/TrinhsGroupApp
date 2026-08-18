package com.trinhskitchen.app.ui.orders

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.Warning
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.trinhsgroup.shared.order.StatusIcon
import com.trinhsgroup.shared.order.StatusTint

/**
 * Maps the shared layer's named status tints and icons onto this platform's palette.
 *
 * The shared code decides *which* tint a stage gets; only the values live here. Hex values are
 * explicit rather than pulled from AppColors so the warm ramp matches iOS — amber while waiting,
 * orange in the kitchen, green when ready.
 */
val StatusTint.color: Color
    get() = when (this) {
        StatusTint.WAITING -> Color(0xFFE9A23B)
        StatusTint.BRAND -> Color(0xFFFE7058)
        StatusTint.COOKING -> Color(0xFFF2682A)
        StatusTint.READY -> Color(0xFF57A733)
        StatusTint.FAILURE -> Color(0xFFE5484D)
    }

val StatusIcon.vector: ImageVector
    get() = when (this) {
        StatusIcon.BAG -> Icons.Filled.ShoppingBag
        StatusIcon.BELL -> Icons.Filled.NotificationsActive
        StatusIcon.FLAME -> Icons.Filled.LocalFireDepartment
        StatusIcon.SEAL -> Icons.Filled.CheckCircle
        StatusIcon.CARD -> Icons.Filled.CreditCard
        StatusIcon.CROSS -> Icons.Filled.Cancel
        StatusIcon.REFUND -> Icons.AutoMirrored.Filled.Undo
        StatusIcon.WARNING -> Icons.Filled.Warning
        StatusIcon.CLOCK -> Icons.Filled.Schedule
    }

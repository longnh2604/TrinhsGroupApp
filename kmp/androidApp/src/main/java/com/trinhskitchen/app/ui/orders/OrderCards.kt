package com.trinhskitchen.app.ui.orders

import android.content.Context
import android.provider.Settings
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.airbnb.lottie.compose.LottieAnimation
import com.airbnb.lottie.compose.LottieCompositionSpec
import com.airbnb.lottie.compose.LottieConstants
import com.airbnb.lottie.compose.rememberLottieComposition
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.LineItem
import com.trinhsgroup.shared.model.Order
import com.trinhsgroup.shared.order.OrderStatusPresentation
import com.trinhsgroup.shared.util.DateTimeUtils
import com.trinhsgroup.shared.util.PriceFormatting
import kotlin.math.abs

/**
 * The cards an order is made of, shared by the confirmation screen and the history detail
 * screen. Mirrors Swift's OrderItemsCard / OrderPaymentSummaryCard, which exist for the same
 * reason: the two screens had separate copies that disagreed about the money.
 */

@Composable
fun OrderStatusHero(presentation: OrderStatusPresentation, placedAt: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = presentation.tint.color.copy(alpha = 0.12f)),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            StatusBadge(presentation)
            Spacer(modifier = Modifier.width(14.dp))
            Column {
                Text(
                    text = presentation.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary
                )
                if (presentation.subtitle.isNotEmpty()) {
                    Text(
                        text = presentation.subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }
                if (placedAt.isNotEmpty()) {
                    Text(
                        text = "Placed ${DateTimeUtils.toDisplayDate(placedAt)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.TextSecondary
                    )
                }
            }
        }
    }
}

/**
 * The animation the status has one for, and its icon otherwise. Same Lottie scenes as iOS, in
 * a 1.6:1 box because these are wide compositions that a square frame letterboxes to half
 * height.
 *
 * A device set to reduce motion gets the first frame, held — the scene still says what the
 * status is without moving.
 */
@Composable
private fun StatusBadge(presentation: OrderStatusPresentation) {
    val lottieName = presentation.lottieName
    if (lottieName == null) {
        Icon(
            imageVector = presentation.icon.vector,
            contentDescription = null,
            tint = presentation.tint.color,
            modifier = Modifier.size(34.dp)
        )
        return
    }

    val composition by rememberLottieComposition(LottieCompositionSpec.Asset("$lottieName.json"))
    val box = Modifier.size(width = 84.dp, height = 52.dp)

    if (animationsEnabled(LocalContext.current)) {
        LottieAnimation(
            composition = composition,
            iterations = LottieConstants.IterateForever,
            modifier = box
        )
    } else {
        LottieAnimation(composition = composition, progress = { 0f }, modifier = box)
    }
}

/** False when the device is set to reduce motion — Android exposes it as a duration scale. */
private fun animationsEnabled(context: Context): Boolean =
    Settings.Global.getFloat(context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f

@Composable
fun OrderItemsCard(order: Order) {
    OrderDetailCard(title = "Items") {
        order.lineItems.forEach { item -> OrderLineItemRow(item) }
    }
}

@Composable
fun OrderPaymentSummaryCard(order: Order) {
    OrderDetailCard(title = "Payment") {
        OrderSummaryRow("Subtotal", PriceFormatting.getPriceAndCurrencySymbol(order.subtotal))

        if (order.discount > 0) {
            OrderSummaryRow(
                label = "Discount",
                value = "-" + PriceFormatting.getPriceAndCurrencySymbol(order.discount),
                valueColor = AppColors.Success
            )
        }

        // Fee lines carry the server's own label — the cash-on-pickup discount arrives
        // here as a negative fee, and older orders still carry the withdrawn app 5%.
        order.fees.forEach { fee ->
            val isDiscount = fee.amount < 0
            OrderSummaryRow(
                label = fee.name.ifEmpty { "Fee" },
                value = (if (isDiscount) "-" else "") +
                    PriceFormatting.getPriceAndCurrencySymbol(abs(fee.amount)),
                valueColor = if (isDiscount) AppColors.Success else AppColors.TextPrimary
            )
        }

        HorizontalDivider(modifier = Modifier.padding(vertical = 8.dp))

        OrderSummaryRow(
            label = "Total",
            value = PriceFormatting.getPriceAndCurrencySymbol(order.total.toDoubleOrNull() ?: 0.0),
            bold = true
        )

        if (order.paymentMethodTitle.isNotEmpty()) {
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = "Paid by ${order.paymentMethodTitle}",
                style = MaterialTheme.typography.bodySmall,
                color = AppColors.TextSecondary
            )
        }
    }
}

@Composable
fun OrderDetailCard(title: String, content: @Composable () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
            content()
        }
    }
}

@Composable
fun OrderSummaryRow(
    label: String,
    value: String,
    bold: Boolean = false,
    valueColor: Color = AppColors.TextPrimary
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
            color = if (bold) AppColors.TextPrimary else AppColors.TextSecondary
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = if (bold) FontWeight.Bold else FontWeight.Normal,
            color = valueColor
        )
    }
}

@Composable
private fun OrderLineItemRow(item: LineItem) {
    Column(modifier = Modifier.padding(vertical = 6.dp)) {
        Row(modifier = Modifier.fillMaxWidth()) {
            Text(
                text = "${item.quantity} × ${item.name}",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextPrimary,
                modifier = Modifier.weight(1f)
            )
            Text(
                text = PriceFormatting.getPriceAndCurrencySymbol(item.total.toDoubleOrNull() ?: 0.0),
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextPrimary
            )
        }

        // What the customer chose, grouped the way the server listed it.
        item.addOnLabels.forEach { label ->
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall,
                color = AppColors.TextSecondary
            )
        }

        item.note?.let { note ->
            Text(
                text = "\"$note\"",
                style = MaterialTheme.typography.bodySmall,
                color = AppColors.TextSecondary
            )
        }
    }
}

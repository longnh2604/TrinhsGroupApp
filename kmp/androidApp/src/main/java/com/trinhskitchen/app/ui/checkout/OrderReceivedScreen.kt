package com.trinhskitchen.app.ui.checkout

import android.app.Activity
import androidx.compose.runtime.LaunchedEffect
import com.trinhskitchen.app.requestStoreReview
import kotlinx.coroutines.delay
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.ui.orders.OrderDetailCard
import com.trinhskitchen.app.ui.orders.OrderItemsCard
import com.trinhskitchen.app.ui.orders.OrderPaymentSummaryCard
import com.trinhskitchen.app.ui.orders.OrderStatusHero
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.order.OrderStatusPresentation
import com.trinhsgroup.shared.util.DateTimeUtils
import com.trinhsgroup.shared.viewmodel.MainViewModel

/**
 * Order received / confirmation screen.
 * Mirrors iOS OrderReceivedView.swift.
 *
 * The hero reads the order's own status through [OrderStatusPresentation] rather than always
 * claiming success: a card payment that is still settling comes back `pending`, and a green tick
 * over "we're preparing it" would be the app telling the customer something it does not know.
 * Items and money come from the same cards as the history detail screen, so the two cannot
 * disagree about what was ordered or what it cost.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderReceivedScreen(
    orderId: Int?,
    mainViewModel: MainViewModel,
    onDismiss: () -> Unit
) {
    val order by mainViewModel.receivedOrder.collectAsState()
    val presentation = OrderStatusPresentation.of(order.status)
    val activity = LocalContext.current as? Activity

    // A completed order is the one moment the app has earned an opinion, same trigger as iOS.
    LaunchedEffect(Unit) {
        delay(1500)
        activity?.let { requestStoreReview(it) }
    }
    val number = order.number.ifEmpty { (orderId ?: order.id).toString() }
    val placed = DateTimeUtils.toDisplayDate(order.dateCreated).takeIf { order.dateCreated.isNotEmpty() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        TopAppBar(
            title = { Text(text = "Checkout", fontWeight = FontWeight.Bold) },
            navigationIcon = {
                IconButton(onClick = onDismiss) {
                    Icon(imageVector = Icons.Default.Close, contentDescription = "Close")
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = AppColors.Background,
                titleContentColor = AppColors.TextPrimary,
                navigationIconContentColor = AppColors.TextPrimary
            )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // This screen's own copy, not the status vocabulary: "we have your order" is a
            // different message from "here is where your order is".
            Text(
                text = "Order Received!",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = AppColors.TextPrimary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
            Text(
                text = "Thank you for your order. We'll let you know as soon as it's ready.",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.TextSecondary,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
            Text(
                text = listOfNotNull("Order #$number", placed).joinToString("  ·  "),
                style = MaterialTheme.typography.bodySmall,
                color = AppColors.TextHint,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )

            OrderStatusHero(presentation = presentation, placedAt = order.dateCreated)

            OrderItemsCard(order)

            OrderPaymentSummaryCard(order)

            if (order.billing.email.isNotEmpty()) {
                OrderDetailCard(title = "Email") {
                    Text(
                        text = order.billing.email,
                        style = MaterialTheme.typography.bodyMedium,
                        color = AppColors.TextPrimary
                    )
                }
            }

            Button(
                onClick = onDismiss,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(25.dp),
                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)
            ) {
                Text(text = "Continue Shopping", fontWeight = FontWeight.Bold, color = Color.White)
            }
        }
    }
}

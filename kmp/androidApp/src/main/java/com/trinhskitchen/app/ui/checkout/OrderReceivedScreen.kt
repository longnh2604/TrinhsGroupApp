package com.trinhskitchen.app.ui.checkout

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.util.PriceFormatting
import com.trinhsgroup.shared.viewmodel.MainViewModel

/**
 * Order received / confirmation screen.
 * Mirrors iOS OrderReceivedView.swift.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderReceivedScreen(
    orderId: Int?,
    mainViewModel: MainViewModel,
    onDismiss: () -> Unit
) {
    val receivedOrder by mainViewModel.receivedOrder.collectAsState()
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF9F9F9))
    ) {
        // Top app bar
        TopAppBar(
            title = {
                Text(
                    text = "Checkout",
                    fontWeight = FontWeight.Bold
                )
            },
            navigationIcon = {
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Close"
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color(0xFFF9F9F9),
                titleContentColor = AppColors.TextPrimary
            )
        )
        
        // Scrollable content
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // Success Header
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Success checkmark
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(CircleShape)
                            .background(Color(0xFF4CAF50)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(48.dp)
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "Order Received!",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.TextPrimary
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = "Thank you for your order. We'll start preparing it right away!",
                        style = MaterialTheme.typography.bodyMedium,
                        color = AppColors.TextSecondary,
                        textAlign = TextAlign.Center
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Order Details
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Order Details",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.TextPrimary
                    )
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    // Order ID
                    OrderDetailRow(
                        label = "Order ID",
                        value = "#${orderId ?: receivedOrder.id}"
                    )
                    
                    // Status
                    OrderDetailRow(
                        label = "Status",
                        value = receivedOrder.status.replaceFirstChar { 
                            if (it.isLowerCase()) it.titlecase() else it.toString() 
                        }
                    )
                    
                    // Payment method
                    OrderDetailRow(
                        label = "Payment Method",
                        value = receivedOrder.paymentMethodTitle.ifEmpty { "N/A" }
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Order Items
            if (receivedOrder.lineItems.isNotEmpty()) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color.White)
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Order Items",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.TextPrimary
                        )
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        receivedOrder.lineItems.forEachIndexed { index, item ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 8.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = item.name,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.Medium,
                                        color = AppColors.TextPrimary
                                    )
                                    Text(
                                        text = "Qty: ${item.quantity}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = AppColors.TextSecondary
                                    )
                                }
                                Text(
                                    text = PriceFormatting.getPriceAndCurrencySymbol(
                                        item.total.toDoubleOrNull() ?: 0.0
                                    ),
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium,
                                    color = AppColors.TextPrimary
                                )
                            }
                            
                            if (index < receivedOrder.lineItems.size - 1) {
                                HorizontalDivider(
                                    modifier = Modifier.padding(vertical = 4.dp),
                                    color = Color.LightGray.copy(alpha = 0.5f)
                                )
                            }
                        }
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Order Total
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    // Subtotal from lineItems
                    val subtotal = receivedOrder.lineItems.sumOf { 
                        it.subtotal.toDoubleOrNull() ?: 0.0 
                    }
                    if (subtotal > 0) {
                        PriceRow(
                            label = "Subtotal",
                            value = PriceFormatting.getPriceAndCurrencySymbol(subtotal)
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                    }
                    
                    // Discount (if any)
                    val discount = receivedOrder.discountTotal.toDoubleOrNull() ?: 0.0
                    if (discount > 0) {
                        PriceRow(
                            label = "Discount",
                            value = "-${PriceFormatting.getPriceAndCurrencySymbol(discount)}"
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                    }
                    
                    HorizontalDivider(
                        modifier = Modifier.padding(vertical = 8.dp),
                        color = Color.LightGray
                    )
                    
                    // Total
                    val totalAmount = receivedOrder.total.toDoubleOrNull() ?: 0.0
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Total",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.TextPrimary
                        )
                        Text(
                            text = PriceFormatting.getPriceAndCurrencySymbol(totalAmount),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = AppColors.Primary
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Continue Shopping Button
            Button(
                onClick = onDismiss,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(25.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = AppColors.Primary
                )
            ) {
                Text(
                    text = "Continue Shopping",
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun OrderDetailRow(
    label: String,
    value: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextSecondary
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = AppColors.TextPrimary
        )
    }
}

@Composable
private fun PriceRow(
    label: String,
    value: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextSecondary
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextPrimary
        )
    }
}

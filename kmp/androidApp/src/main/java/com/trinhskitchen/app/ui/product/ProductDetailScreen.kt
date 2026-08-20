package com.trinhskitchen.app.ui.product

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.AddOnGroup
import com.trinhsgroup.shared.model.AddOnSelection
import com.trinhsgroup.shared.model.displayTotal
import kotlin.math.abs
import com.trinhsgroup.shared.model.AnyCodableValue
import com.trinhsgroup.shared.model.Product
import com.trinhsgroup.shared.model.ProductMetaData
import com.trinhsgroup.shared.util.HtmlDecoder
import com.trinhsgroup.shared.util.PriceFormatting
import com.trinhsgroup.shared.viewmodel.MainViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * Product detail screen.
 * Mirrors iOS ProductDetailsCard.swift.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ProductDetailScreen(
    productId: Int,
    viewModel: MainViewModel,
    onNavigateBack: () -> Unit
) {
    
    // Select the product when the screen loads
    LaunchedEffect(productId) {
        viewModel.selectProductById(productId)
    }
    
    val selectedProduct by viewModel.selectedProduct.collectAsState()
    val favoriteIds by viewModel.favoriteProductIDs.collectAsState()

    // Add to cart animation state
    var isAdded by remember { mutableStateOf(false) }

    // The add-on groups YITH offers for this product, and what the customer picked. Held per
    // screen: the Firestore add-ons this replaces lived on a client keyed by category, so a
    // second product in the same category inherited the first one's ticks.
    var addOnGroups by remember { mutableStateOf<List<AddOnGroup>>(emptyList()) }
    var selection by remember { mutableStateOf(AddOnSelection()) }
    var addOnError by remember { mutableStateOf<String?>(null) }
    var note by remember { mutableStateOf("") }

    val product = selectedProduct

    LaunchedEffect(product?.id) {
        val id = product?.id ?: return@LaunchedEffect
        addOnGroups = emptyList()
        selection = AddOnSelection()
        viewModel.onFetchAddOnGroups(id) { addOnGroups = it }
    }

    val basePrice = product?.let {
        if (it.salePrice > 0) it.salePrice else it.regularPrice
    } ?: 0.0

    val chosen = selection.choices(addOnGroups)
    // Indicative only. The server prices the order, and checkout shows its figure.
    val addOnsTotal = chosen.displayTotal
    val totalPrice = basePrice + addOnsTotal
    
    if (product == null) {
        // Loading or not found state
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(color = AppColors.Primary)
                Spacer(modifier = Modifier.height(16.dp))
                Text(
                    text = "Loading product...",
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppColors.TextSecondary
                )
            }
        }
        return
    }
    
    val isFavorite = favoriteIds.contains(product.id)
    
    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
        ) {
            // Scrollable content
            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
            ) {
                // Image slider
                Box {
                    if (product.images.isNotEmpty()) {
                        val pagerState = rememberPagerState(pageCount = { product.images.size })
                        
                        HorizontalPager(
                            state = pagerState,
                            modifier = Modifier
                                .fillMaxWidth()
                                .aspectRatio(4f / 3f)
                        ) { page ->
                            AsyncImage(
                                model = product.images[page].src,
                                contentDescription = product.name,
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Crop
                            )
                        }
                        
                        // Page indicator
                        if (product.images.size > 1) {
                            Row(
                                modifier = Modifier
                                    .align(Alignment.BottomCenter)
                                    .padding(bottom = 12.dp),
                                horizontalArrangement = Arrangement.Center
                            ) {
                                repeat(product.images.size) { index ->
                                    Box(
                                        modifier = Modifier
                                            .padding(horizontal = 4.dp)
                                            .size(8.dp)
                                            .clip(CircleShape)
                                            .background(
                                                if (pagerState.currentPage == index)
                                                    AppColors.Primary
                                                else
                                                    Color.White.copy(alpha = 0.5f)
                                            )
                                    )
                                }
                            }
                        }
                    } else {
                        // Placeholder when no images
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .aspectRatio(4f / 3f)
                                .background(AppColors.SurfaceVariant),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No Image",
                                color = AppColors.TextSecondary
                            )
                        }
                    }
                    
                    // Favorite button
                    Surface(
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(12.dp),
                        shape = CircleShape,
                        color = Color.White.copy(alpha = 0.9f),
                        shadowElevation = 4.dp
                    ) {
                        IconButton(
                            onClick = { viewModel.toggleFavorite(product) }
                        ) {
                            Icon(
                                imageVector = if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                                contentDescription = if (isFavorite) "Remove from favorites" else "Add to favorites",
                                tint = if (isFavorite) AppColors.Primary else Color.Gray
                            )
                        }
                    }
                }
                
                // Product info
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color.White)
                        .padding(16.dp)
                ) {
                    // Short description
                    val shortDesc = HtmlDecoder.decode(product.shortDescription)
                    if (shortDesc.isNotBlank()) {
                        Text(
                            text = shortDesc,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = AppColors.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                    }
                    
                    // Product name
                    Text(
                        text = product.name,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.TextPrimary
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // Price
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        if (product.salePrice > 0 && product.regularPrice > product.salePrice) {
                            Text(
                                text = PriceFormatting.getPriceAndCurrencySymbol(product.salePrice),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = AppColors.TextPrimary
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = PriceFormatting.getPriceAndCurrencySymbol(product.regularPrice),
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.Gray,
                                textDecoration = TextDecoration.LineThrough
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            val discount = ((product.regularPrice - product.salePrice) / product.regularPrice * 100).toInt()
                            Text(
                                text = "-$discount%",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium,
                                color = AppColors.Primary
                            )
                        } else {
                            Text(
                                text = PriceFormatting.getPriceAndCurrencySymbol(product.regularPrice),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = AppColors.TextPrimary
                            )
                        }
                    }
                }
                
                // Divider
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .background(AppColors.Background)
                )
                
                // Product description
                val description = HtmlDecoder.decode(product.description)
                if (description.isNotBlank()) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color.White)
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Product Details",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = AppColors.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = description,
                            style = MaterialTheme.typography.bodyMedium,
                            color = AppColors.TextSecondary,
                            lineHeight = 22.sp
                        )
                    }
                }
                
                // Add-on groups from YITH (mirrors iOS AddOnGroupsView)
                if (addOnGroups.isNotEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(8.dp)
                            .background(AppColors.Background)
                    )

                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color.White)
                            .padding(16.dp)
                    ) {
                        Text(
                            text = "Make it yours",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = AppColors.TextPrimary
                        )

                        addOnGroups.forEach { group ->
                            Spacer(modifier = Modifier.height(16.dp))

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = group.title,
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.SemiBold,
                                    color = AppColors.TextPrimary
                                )
                                if (group.required && !group.conditional) {
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = "Required",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = AppColors.Primary
                                    )
                                }
                            }

                            group.limitHint()?.let { hint ->
                                Text(
                                    text = hint,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = AppColors.TextSecondary
                                )
                            }

                            group.options.forEach { option ->
                                val isChosen = selection.isChosen(group, option)
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clickable {
                                            selection = selection.toggle(group, option)
                                            addOnError = null
                                        }
                                        .padding(vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    // A group that takes one answer reads as a radio, even though
                                    // tapping the chosen option clears it.
                                    if (group.allowsMultiple) {
                                        Checkbox(
                                            checked = isChosen,
                                            onCheckedChange = {
                                                selection = selection.toggle(group, option)
                                                addOnError = null
                                            },
                                            colors = CheckboxDefaults.colors(
                                                checkedColor = AppColors.Primary,
                                                uncheckedColor = Color.Gray
                                            )
                                        )
                                    } else {
                                        RadioButton(
                                            selected = isChosen,
                                            onClick = {
                                                selection = selection.toggle(group, option)
                                                addOnError = null
                                            },
                                            colors = RadioButtonDefaults.colors(
                                                selectedColor = AppColors.Primary,
                                                unselectedColor = Color.Gray
                                            )
                                        )
                                    }

                                    Text(
                                        text = option.label,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = AppColors.TextPrimary,
                                        modifier = Modifier.weight(1f)
                                    )

                                    option.displayPrice?.let { price ->
                                        Text(
                                            text = (if (price < 0) "(-" else "(+") +
                                                PriceFormatting.getPriceAndCurrencySymbol(abs(price)) + ")",
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = AppColors.TextSecondary
                                        )
                                    }
                                }
                            }
                        }

                        if (addOnsTotal != 0.0) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = "Total with add-ons:",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium,
                                    color = AppColors.TextPrimary
                                )
                                Text(
                                    text = PriceFormatting.getPriceAndCurrencySymbol(totalPrice),
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.Bold,
                                    color = AppColors.Primary
                                )
                            }
                        }

                        addOnError?.let { message ->
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = message,
                                style = MaterialTheme.typography.bodySmall,
                                color = AppColors.Primary
                            )
                        }
                    }
                }

                // Special note for the kitchen, sent as `_note` line-item meta.
                OutlinedTextField(
                    value = note,
                    onValueChange = { note = it },
                    label = { Text("Special note (optional)") },
                    placeholder = { Text("No chilli, extra herbs…") },
                    minLines = 2,
                    maxLines = 4,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                )

                // Bottom spacing for the Add to Cart button
                Spacer(modifier = Modifier.height(80.dp))
            }
            
            // Add to Cart button (fixed at bottom)
            Button(
                onClick = {
                    // The server will not price a basket that breaks the group rules, so catch
                    // it here rather than at checkout.
                    selection.missingRequired(addOnGroups)?.let { group ->
                        addOnError = "Please choose ${group.title}"
                        return@Button
                    }
                    selection.outOfRange(addOnGroups)?.let { group ->
                        addOnError = group.limitHint() ?: "Check your ${group.title} choices"
                        return@Button
                    }

                    // price stays the catalog price: the server prices the order, and
                    // overwriting it here only ever made the app disagree with the receipt.
                    val filteredOriginalMetaData = product.metaData.filter {
                        !it.key.contains("_") || it.key == "_note"
                    }

                    val trimmedNote = note.trim()
                    val cartProduct = product.copy(
                        metaData = if (trimmedNote.isEmpty()) {
                            filteredOriginalMetaData
                        } else {
                            filteredOriginalMetaData + ProductMetaData(
                                id = 0,
                                key = "_note",
                                value = AnyCodableValue.StringValue(trimmedNote)
                            )
                        },
                        addOnChoices = chosen
                    )

                    viewModel.add(cartProduct)
                    selection = AddOnSelection()
                    note = ""
                    addOnError = null

                    // Show added animation
                    isAdded = true
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(70.dp)
                    .padding(horizontal = 0.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = AppColors.Primary
                )
            ) {
                if (isAdded) {
                    Icon(
                        imageVector = Icons.Filled.CheckCircle,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text(
                    text = if (isAdded) "Added!" else "Add To Cart",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }
            
            // Reset isAdded after delay
            LaunchedEffect(isAdded) {
                if (isAdded) {
                    delay(1000)
                    isAdded = false
                }
            }
        }
        
        // Close button (fixed at top right, doesn't scroll)
        Surface(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(top = 48.dp, end = 16.dp),
            shape = CircleShape,
            color = Color.White.copy(alpha = 0.9f),
            shadowElevation = 4.dp
        ) {
            IconButton(onClick = onNavigateBack) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = "Close",
                    tint = Color.Black
                )
            }
        }
    }
}

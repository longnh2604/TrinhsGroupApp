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
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import com.trinhskitchen.app.firebase.FirestoreClient
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.AnyCodableValue
import com.trinhsgroup.shared.model.Product
import com.trinhsgroup.shared.model.ProductAddOns
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
    firestoreClient: FirestoreClient,
    onNavigateBack: () -> Unit
) {
    val scope = rememberCoroutineScope()
    
    // Select the product when the screen loads
    LaunchedEffect(productId) {
        viewModel.selectProductById(productId)
    }
    
    val selectedProduct by viewModel.selectedProduct.collectAsState()
    val favoriteIds by viewModel.favoriteProductIDs.collectAsState()
    val productAddOns by firestoreClient.productAddOns.collectAsState()
    
    // Add to cart animation state
    var isAdded by remember { mutableStateOf(false) }
    
    // Track selected add-ons - using map with addon content as key
    val selectedAddOns = remember { mutableStateMapOf<String, Boolean>() }
    
    val product = selectedProduct
    
    // Load add-ons when product is available
    LaunchedEffect(product) {
        product?.categories?.firstOrNull()?.id?.let { categoryId ->
            scope.launch {
                firestoreClient.fetchProductAddOns(categoryId)
            }
        }
    }
    
    // Reset selected add-ons when add-ons list changes
    LaunchedEffect(productAddOns) {
        selectedAddOns.clear()
        productAddOns.forEach { addon ->
            selectedAddOns[addon.content] = false
        }
    }
    
    // Calculate total price including selected add-ons
    val basePrice = product?.let {
        if (it.salePrice > 0) it.salePrice else it.regularPrice
    } ?: 0.0
    
    val addOnsTotal = productAddOns
        .filter { selectedAddOns[it.content] == true }
        .sumOf { it.value.toDouble() }
    
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
                
                // Product Add-ons Section (mirrors iOS productAddOns section)
                if (productAddOns.isNotEmpty()) {
                    // Divider
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
                            text = "Add-ons",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            color = AppColors.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        productAddOns.forEach { addon ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        selectedAddOns[addon.content] = !(selectedAddOns[addon.content] ?: false)
                                    }
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Checkbox(
                                    checked = selectedAddOns[addon.content] ?: false,
                                    onCheckedChange = { checked ->
                                        selectedAddOns[addon.content] = checked
                                    },
                                    colors = CheckboxDefaults.colors(
                                        checkedColor = AppColors.Primary,
                                        uncheckedColor = Color.Gray
                                    )
                                )
                                Text(
                                    text = addon.content,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = AppColors.TextPrimary,
                                    modifier = Modifier.weight(1f)
                                )
                                if (addon.value > 0) {
                                    Text(
                                        text = "(+${PriceFormatting.getPriceAndCurrencySymbol(addon.value.toDouble())})",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = AppColors.TextSecondary
                                    )
                                }
                            }
                        }
                        
                        // Show total with add-ons if any selected
                        if (addOnsTotal > 0) {
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
                    }
                }
                
                // Bottom spacing for the Add to Cart button
                Spacer(modifier = Modifier.height(80.dp))
            }
            
            // Add to Cart button (fixed at bottom)
            Button(
                onClick = {
                    // Build new product with selected add-ons (mirrors iOS AddToCartButton logic)
                    var newPrice = basePrice
                    val newMetaData = mutableListOf<ProductMetaData>()
                    
                    // Add selected add-ons to meta_data and update price
                    productAddOns.forEach { addon ->
                        if (selectedAddOns[addon.content] == true) {
                            newMetaData.add(
                                ProductMetaData(
                                    id = addon.id,
                                    key = addon.content,
                                    value = AnyCodableValue.StringValue(addon.value.toString())
                                )
                            )
                            newPrice += addon.value
                        }
                    }
                    
                    // Filter out internal meta_data keys from original (same as iOS)
                    val filteredOriginalMetaData = product.metaData.filter { 
                        !it.key.contains("_") || it.key == "_note" 
                    }
                    
                    // Create product with updated price and add-ons
                    val cartProduct = product.copy(
                        price = newPrice,
                        regularPrice = newPrice,
                        metaData = filteredOriginalMetaData + newMetaData
                    )
                    
                    viewModel.add(cartProduct)
                    
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

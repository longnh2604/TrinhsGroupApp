package com.trinhskitchen.app.ui.menu

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.trinhskitchen.app.ui.components.CartAction
import com.trinhskitchen.app.ui.components.ProductCard
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.Category
import com.trinhsgroup.shared.viewmodel.MainViewModel

/**
 * Menu screen with category list and products.
 * Mirrors iOS CategoryView.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MenuScreen(
    viewModel: MainViewModel,
    onNavigateToProductDetail: (Int) -> Unit,
    onOpenCart: () -> Unit
) {
    val isLoading by viewModel.showLoading.collectAsState()
    val isCategoryProductsLoading by viewModel.isCategoryProductsLoading.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val selectedCategory by viewModel.selectedCategory.collectAsState()
    val categoryProducts by viewModel.categoryProducts.collectAsState()
    val favoriteIds by viewModel.favoriteProductIDs.collectAsState()
    
    // Fetch categories if not loaded
    LaunchedEffect(Unit) {
        if (categories.isEmpty()) {
            viewModel.onFetchCategories()
        }
    }
    
    // Fetch products when category changes
    LaunchedEffect(selectedCategory) {
        if (selectedCategory.id != Category.Default.id) {
            viewModel.onFetchSelectedCategoryProducts(selectedCategory.id)
        }
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        // Top app bar
        TopAppBar(
            title = {
                Text(
                    text = "Menu",
                    fontWeight = FontWeight.Bold
                )
            },
            actions = { CartAction(viewModel = viewModel, onOpenCart = onOpenCart) },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = AppColors.Primary,
                titleContentColor = Color.White,
                actionIconContentColor = Color.White
            )
        )
        
        if (isLoading && categories.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = AppColors.Primary)
            }
        } else {
            Column(modifier = Modifier.fillMaxSize()) {
                // Category chips
                LazyRow(
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(categories) { category ->
                        FilterChip(
                            selected = selectedCategory.id == category.id,
                            onClick = { viewModel.setSelectedCategory(category) },
                            label = { Text(category.name) },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = AppColors.Primary,
                                selectedLabelColor = Color.White
                            )
                        )
                    }
                }
                
                // Products grid
                if (isCategoryProductsLoading) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = AppColors.Primary)
                    }
                } else if (categoryProducts.isEmpty() && selectedCategory.id != Category.Default.id) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No products in this category",
                            style = MaterialTheme.typography.bodyLarge,
                            color = AppColors.TextSecondary
                        )
                    }
                } else if (selectedCategory.id == Category.Default.id && categories.isNotEmpty()) {
                    // Show category cards when no category selected
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(categories) { category ->
                            CategoryGridCard(
                                category = category,
                                onClick = { viewModel.setSelectedCategory(category) }
                            )
                        }
                    }
                } else {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        contentPadding = PaddingValues(16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(categoryProducts) { product ->
                            ProductCard(
                                product = product,
                                isFavorite = favoriteIds.contains(product.id),
                                onClick = { onNavigateToProductDetail(product.id) },
                                onFavoriteClick = { viewModel.toggleFavorite(product) },
                                onAddToCart = {
                                    // Filter out internal meta_data keys before adding
                                    val cleanProduct = product.copy(
                                        metaData = product.metaData.filter { !it.key.contains("_") }
                                    )
                                    viewModel.add(cleanProduct)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CategoryGridCard(
    category: Category,
    onClick: () -> Unit
) {
    val imageUrl = category.image?.src
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(120.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Category image
            if (imageUrl != null) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = category.name,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
                // Overlay
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.3f))
                )
            }
            
            // Category name
            Text(
                text = category.name,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = if (imageUrl != null) Color.White else AppColors.TextPrimary,
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(8.dp)
            )
        }
    }
}

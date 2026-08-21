package com.trinhskitchen.app.ui.favorites

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.trinhskitchen.app.ui.components.AppTopBar
import com.trinhskitchen.app.ui.components.CartAction
import com.trinhskitchen.app.ui.components.ProductCard
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.viewmodel.MainViewModel

/**
 * Favorites tab.
 * Mirrors iOS FavoriteView.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FavoritesScreen(
    viewModel: MainViewModel,
    onNavigateToProductDetail: (Int) -> Unit,
    onOpenCart: () -> Unit
) {
    val favorites by viewModel.favoriteProducts.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        AppTopBar(
            title = "Favorite",
            actions = { CartAction(viewModel = viewModel, onOpenCart = onOpenCart) }
        )

        if (favorites.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(horizontal = 24.dp)
                ) {
                    Icon(
                        imageVector = Icons.Outlined.FavoriteBorder,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = AppColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "No favorites yet",
                        style = MaterialTheme.typography.titleMedium,
                        color = AppColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Tap the heart on any product to save it here.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = AppColors.TextHint,
                        textAlign = TextAlign.Center
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
                items(favorites, key = { it.id }) { product ->
                    ProductCard(
                        product = product,
                        isFavorite = true,
                        onClick = { onNavigateToProductDetail(product.id) },
                        onFavoriteClick = { viewModel.toggleFavorite(product) },
                        onAddToCart = {
                            // Same meta_data scrub the Menu grid does before adding.
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

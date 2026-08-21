package com.trinhskitchen.app.ui.home

import androidx.compose.foundation.ExperimentalFoundationApi
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.trinhskitchen.app.R
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.trinhskitchen.app.firebase.EventsRepository
import com.trinhskitchen.app.ui.components.CartAction
import com.trinhskitchen.app.ui.components.HorizontalProductCard
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.model.Category
import com.trinhsgroup.shared.model.AppEvent
import com.trinhsgroup.shared.storage.NotificationStore
import com.trinhsgroup.shared.viewmodel.MainViewModel
import org.koin.compose.koinInject

/**
 * Home screen.
 * Mirrors iOS HomeView.
 */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HomeScreen(
    viewModel: MainViewModel,
    onNavigateToProductDetail: (Int) -> Unit,
    onOpenCart: () -> Unit,
    onNavigateToCategory: (Int) -> Unit,
    onNavigateToNotifications: () -> Unit
) {
    val isLoading by viewModel.showLoading.collectAsState()
    val categories by viewModel.categories.collectAsState()
    val popularProducts by viewModel.popularProducts.collectAsState()
    val eventsRepository: EventsRepository = koinInject()
    val notificationStore: NotificationStore = koinInject()
    val notifications by notificationStore.notifications.collectAsState()
    val events by eventsRepository.events.collectAsState()
    var posterEvent by remember { mutableStateOf<AppEvent?>(null) }
    
    // Fetch data on first load
    LaunchedEffect(Unit) {
        viewModel.onFetchCategories()
        viewModel.onFetchPopularProducts()
        eventsRepository.start()
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
                    text = "TrinhsGroup",
                    fontWeight = FontWeight.Bold
                )
            },
            actions = {
                IconButton(onClick = onNavigateToNotifications) {
                    BadgedBox(
                        badge = {
                            val unread = notifications.count { !it.isRead }
                            if (unread > 0) Badge { Text(text = unread.toString()) }
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Notifications,
                            contentDescription = "Notifications"
                        )
                    }
                }
                CartAction(viewModel = viewModel, onOpenCart = onOpenCart)
            },
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
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                // Events carousel — artwork and wording both come from Firestore.
                if (events.isNotEmpty()) {
                    SectionHeader(title = "Events")

                    val pagerState = rememberPagerState(pageCount = { events.size })

                    Column(modifier = Modifier.fillMaxWidth()) {
                        HorizontalPager(
                            state = pagerState,
                            contentPadding = PaddingValues(horizontal = 16.dp),
                            pageSpacing = 12.dp,
                            modifier = Modifier.fillMaxWidth()
                        ) { page ->
                            EventBannerCard(
                                event = events[page],
                                onOpenPoster = { posterEvent = events[page] }
                            )
                        }

                        if (events.size > 1) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 8.dp),
                                horizontalArrangement = Arrangement.Center
                            ) {
                                repeat(events.size) { index ->
                                    Box(
                                        modifier = Modifier
                                            .padding(horizontal = 4.dp)
                                            .size(8.dp)
                                            .clip(CircleShape)
                                            .background(
                                                if (pagerState.currentPage == index) AppColors.Primary
                                                else Color.Gray.copy(alpha = 0.3f)
                                            )
                                    )
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                }

                // Categories section
                if (categories.isNotEmpty()) {
                    SectionHeader(
                        title = "Categories",
                        onSeeAllClick = { /* Navigate to all categories */ }
                    )
                    
                    LazyRow(
                        contentPadding = PaddingValues(horizontal = 16.dp),
                        horizontalArrangement = Arrangement.spacedBy(20.dp)
                    ) {
                        items(categories) { category ->
                            CategoryCard(
                                category = category,
                                onClick = { onNavigateToCategory(category.id) }
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(16.dp))
                }
                
                // Popular products section (horizontal cards like iOS)
                if (popularProducts.isNotEmpty()) {
                    SectionHeader(
                        title = "Popular",
                        onSeeAllClick = { /* Navigate to all popular */ }
                    )
                    
                    Column(
                        modifier = Modifier.padding(horizontal = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        popularProducts.forEach { product ->
                            HorizontalProductCard(
                                product = product,
                                onClick = { onNavigateToProductDetail(product.id) },
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
                    
                    Spacer(modifier = Modifier.height(24.dp))
                }
            }
        }
    }

    posterEvent?.let { event ->
        EventPosterDialog(event = event, onDismiss = { posterEvent = null })
    }
}

@Composable
private fun SectionHeader(
    title: String,
    onSeeAllClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        
        if (onSeeAllClick != null) {
            Text(
                text = "See All",
                style = MaterialTheme.typography.bodyMedium,
                color = AppColors.Primary,
                modifier = Modifier.clickable(onClick = onSeeAllClick)
            )
        }
    }
}

@Composable
private fun CategoryCard(
    category: Category,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Category image (60x60 circle like iOS)
        val imageUrl = category.image?.src
        Box(
            modifier = Modifier
                .size(60.dp)
                .clip(CircleShape)
                .background(AppColors.SurfaceVariant),
            contentAlignment = Alignment.Center
        ) {
            if (imageUrl != null) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = category.name,
                    modifier = Modifier
                        .fillMaxSize()
                        .clip(CircleShape),
                    contentScale = ContentScale.Crop,
                    error = painterResource(R.drawable.ic_noimage),
                    placeholder = painterResource(R.drawable.ic_noimage)
                )
            } else {
                Text(
                    text = category.name.take(2).uppercase(),
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.Primary
                )
            }
        }
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = category.name,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium,
            maxLines = 1
        )
    }
}

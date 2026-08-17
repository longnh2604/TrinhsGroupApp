package com.trinhskitchen.app.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.trinhskitchen.app.ui.theme.AppColors
import com.trinhsgroup.shared.util.PriceFormatting
import com.trinhsgroup.shared.viewmodel.AuthViewModel
import com.trinhsgroup.shared.viewmodel.HistoryViewModel
import com.trinhsgroup.shared.viewmodel.MainViewModel
import com.trinhsgroup.shared.viewmodel.PointsViewModel

/**
 * Profile screen.
 * Mirrors iOS ProfileView.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    authViewModel: AuthViewModel,
    historyViewModel: HistoryViewModel,
    pointsViewModel: PointsViewModel,
    mainViewModel: MainViewModel,
    onNavigateToOrderDetail: (Int) -> Unit,
    onLogout: () -> Unit
) {
    val user by authViewModel.user.collectAsState()
    val balance by pointsViewModel.balance.collectAsState()
    val orders by historyViewModel.orders.collectAsState()
    val favoriteProducts by mainViewModel.favoriteProducts.collectAsState()
    
    // Fetch user data
    LaunchedEffect(Unit) {
        authViewModel.onGetUser()
        pointsViewModel.fetchPoints()
        historyViewModel.fetchOrders()
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
                    text = "Profile",
                    fontWeight = FontWeight.Bold
                )
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = AppColors.Primary,
                titleContentColor = Color.White
            )
        )
        
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // User info card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Avatar
                    Box(
                        modifier = Modifier
                            .size(60.dp)
                            .clip(CircleShape)
                            .background(AppColors.Primary),
                        contentAlignment = Alignment.Center
                    ) {
                        if (user.avatarUrl != null) {
                            AsyncImage(
                                model = user.avatarUrl,
                                contentDescription = "Profile picture",
                                modifier = Modifier.fillMaxSize()
                            )
                        } else {
                            Text(
                                text = user.firstName.take(1).uppercase().ifEmpty { user.email.take(1).uppercase() },
                                style = MaterialTheme.typography.headlineMedium,
                                color = Color.White,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "${user.firstName} ${user.lastName}".ifBlank { user.username },
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = user.email,
                            style = MaterialTheme.typography.bodyMedium,
                            color = AppColors.TextSecondary
                        )
                    }
                }
            }
            
            // Points card
            if (balance != null) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = AppColors.Primary)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "Reward Points",
                                style = MaterialTheme.typography.bodyMedium,
                                color = Color.White.copy(alpha = 0.8f)
                            )
                            Text(
                                text = "${balance?.toInt() ?: 0} points",
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                        
                        Icon(
                            imageVector = Icons.Default.CardGiftcard,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(40.dp)
                        )
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Menu items
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Column {
                    ProfileMenuItem(
                        icon = Icons.Default.Person,
                        title = "Edit Profile",
                        onClick = { /* Navigate to edit profile */ }
                    )
                    
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
                    
                    ProfileMenuItem(
                        icon = Icons.Default.LocationOn,
                        title = "Edit Address",
                        onClick = { /* Navigate to edit address */ }
                    )
                    
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
                    
                    ProfileMenuItem(
                        icon = Icons.Default.History,
                        title = "My Orders",
                        subtitle = "${orders.size} orders",
                        onClick = { /* Navigate to orders */ }
                    )
                    
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
                    
                    ProfileMenuItem(
                        icon = Icons.Default.Favorite,
                        title = "Favorites",
                        subtitle = "${favoriteProducts.size} items",
                        onClick = { /* Navigate to favorites */ }
                    )
                    
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
                    
                    ProfileMenuItem(
                        icon = Icons.Default.CardGiftcard,
                        title = "Rewards Center",
                        onClick = { /* Navigate to rewards */ }
                    )
                    
                    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
                    
                    ProfileMenuItem(
                        icon = Icons.Default.Settings,
                        title = "Settings",
                        onClick = { /* Navigate to settings */ }
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Logout button
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .clickable(onClick = onLogout),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ExitToApp,
                        contentDescription = null,
                        tint = AppColors.Error
                    )
                    
                    Spacer(modifier = Modifier.width(16.dp))
                    
                    Text(
                        text = "Logout",
                        style = MaterialTheme.typography.bodyLarge,
                        color = AppColors.Error
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun ProfileMenuItem(
    icon: ImageVector,
    title: String,
    subtitle: String? = null,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = AppColors.Primary
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = AppColors.TextSecondary
                )
            }
        }
        
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = AppColors.TextSecondary
        )
    }
}

package com.trinhskitchen.app.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.unit.dp
import coil3.compose.SubcomposeAsyncImage
import com.trinhskitchen.app.R

/**
 * Remote food image with the same three states as iOS `OptimizedKFImage`: the shimmering
 * food placeholder while downloading, the image once it arrives, and `ic_noimage` if the
 * download fails.
 */
@Composable
fun FoodImage(
    url: String?,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop
) {
    SubcomposeAsyncImage(
        model = url,
        contentDescription = contentDescription,
        modifier = modifier,
        contentScale = contentScale,
        loading = { FoodImageLoadingPlaceholder() },
        error = {
            Icon(
                painter = painterResource(R.drawable.ic_noimage),
                contentDescription = null,
                tint = Color.Unspecified,
                modifier = Modifier.fillMaxSize()
            )
        }
    )
}

/**
 * Temporary state shown while a remote food image downloads. Mirrors the iOS
 * `FoodImageLoadingPlaceholder`: a warm gradient, a dish glyph, a short bar, and a
 * diagonal shimmer sweep.
 */
@Composable
fun FoodImageLoadingPlaceholder(modifier: Modifier = Modifier) {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val sweep by transition.animateFloat(
        initialValue = -1f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1250, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "sweep"
    )

    BoxWithConstraints(
        modifier = modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    listOf(Color(0xFFFDF2E8), Color.White)
                )
            )
            // Decorative, and it is replaced as soon as the image lands.
            .clearAndSetSemantics { },
        contentAlignment = Alignment.Center
    ) {
        val glyph = minOf(maxWidth, maxHeight) * 0.24f
        val barWidth = minOf(maxWidth * 0.42f, 72.dp)

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Restaurant,
                contentDescription = null,
                tint = Color.Red.copy(alpha = 0.45f),
                modifier = Modifier.size(glyph)
            )
            Box(
                modifier = Modifier
                    .width(barWidth)
                    .height(6.dp)
                    .clip(CircleShape)
                    .background(Color.Red.copy(alpha = 0.16f))
            )
        }

        // Diagonal band travelling across the tile, as the iOS rotated gradient does.
        val span = maxWidth.value * 2f
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.linearGradient(
                        colors = listOf(Color.Transparent, Color.White.copy(alpha = 0.65f), Color.Transparent),
                        start = Offset(sweep * span, 0f),
                        end = Offset(sweep * span + span / 3f, maxHeight.value)
                    )
                )
        )
    }
}

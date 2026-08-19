package com.trinhskitchen.app.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import coil3.compose.AsyncImage
import com.trinhsgroup.shared.model.AppEvent

/** The poster palette, shared with iOS EventBannerCard. */
private val PosterRed = Color(0xFFB3231B)
private val PosterCream = Color(0xFFF8EFE1)
private val PosterInk = Color(0xFF3B2A1F)
private val PosterChip = Color(0xFFF5C95C)

/**
 * One event in the Home carousel: the app draws eyebrow/title/subtitle/detail over plain
 * artwork, so the wording is edited in Firestore rather than baked into an image.
 * Mirrors iOS EventBannerCard.
 */
@Composable
fun EventBannerCard(
    event: AppEvent,
    onOpenPoster: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            // 196dp is the iOS card; Compose's type runs a little taller, so let a long
            // subtitle grow the card rather than clip "View poster" off the bottom.
            .heightIn(min = 196.dp)
            .semantics { contentDescription = event.accessibilityLabel }
            .then(
                if (event.posterURL.isNotEmpty()) Modifier.clickable(onClick = onOpenPoster)
                else Modifier
            ),
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = PosterCream),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(modifier = Modifier.fillMaxSize()) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = 16.dp, top = 14.dp, bottom = 14.dp, end = 10.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                // Each line is skipped when its field is blank, so a half-filled document
                // reads as a smaller card rather than one with holes in it.
                if (event.eyebrow.isNotEmpty()) {
                    Text(
                        text = event.eyebrow,
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.1.sp,
                        color = PosterRed,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Text(
                    text = event.title,
                    fontSize = 21.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = PosterRed,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                if (event.subtitle.isNotEmpty()) {
                    Text(
                        text = event.subtitle,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = PosterInk,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                if (event.detail.isNotEmpty()) {
                    Text(
                        text = event.detail,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = PosterInk,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(PosterChip.copy(alpha = 0.45f))
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }

                if (event.posterURL.isNotEmpty()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "View poster",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = PosterRed
                        )
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                            contentDescription = null,
                            tint = PosterRed,
                            modifier = Modifier.size(14.dp)
                        )
                    }
                }
            }

            AsyncImage(
                model = event.imgURL,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .width(140.dp)
                    .fillMaxHeight()
            )
        }
    }
}

/**
 * Full-screen poster.
 * Mirrors iOS EventPosterView.
 */
@Composable
fun EventPosterDialog(event: AppEvent, onDismiss: () -> Unit) {
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.92f))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(12.dp),
                contentAlignment = Alignment.Center
            ) {
                AsyncImage(
                    model = event.posterURL,
                    contentDescription = event.title,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                )
            }

            IconButton(
                onClick = onDismiss,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(16.dp)
                    .size(34.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.15f))
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = "Close poster",
                    tint = Color.White
                )
            }
        }
    }
}

package com.trinhskitchen.app.ui.onboard

import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.rememberScrollState
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
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.Circle
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.trinhskitchen.app.R
import com.trinhskitchen.app.ui.theme.AppColors
import kotlinx.coroutines.launch

/**
 * First-launch welcome carousel. Mirrors iOS `OnboardingView`, including the slide art:
 * each slide previews the real screen it describes — category illustrations from the menu,
 * an add-on group, the same-day pickup slots, a voucher — rather than a generic icon.
 *
 * Shown once before the main shell; the flag is written by [onFinished], which both Skip
 * and Get Started call.
 */
@Composable
fun OnboardingScreen(onFinished: () -> Unit) {
    val slides = Slide.entries
    val pagerState = rememberPagerState(pageCount = { slides.size })
    val scope = rememberCoroutineScope()
    val isLastPage = pagerState.currentPage == slides.lastIndex

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Surface)
            // The activity draws edge to edge, so Skip would sit under the status bar.
            .systemBarsPadding()
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.End
        ) {
            TextButton(onClick = onFinished) {
                Text(
                    text = "Skip",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.BarIcon
                )
            }
        }

        HorizontalPager(
            state = pagerState,
            modifier = Modifier.weight(1f)
        ) { page ->
            SlideBody(slides[page])
        }

        PageDots(current = pagerState.currentPage, count = slides.size)

        Button(
            onClick = {
                if (isLastPage) {
                    onFinished()
                } else {
                    scope.launch { pagerState.animateScrollToPage(pagerState.currentPage + 1) }
                }
            },
            shape = RoundedCornerShape(27.dp),
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary),
            modifier = Modifier
                .padding(horizontal = 32.dp)
                .padding(bottom = 32.dp)
                .fillMaxWidth()
                .height(54.dp)
        ) {
            Text(
                text = if (isLastPage) "Get Started" else "Next",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }
    }
}

/**
 * Slide copy is checked against the real flow: pickup is same-day only, and rewards run
 * points to vouchers.
 */
private enum class Slide(
    val title: String,
    val body: String,
    val tint: Color
) {
    MENU(
        title = "The whole menu, in your pocket",
        body = "Browse by category — phở, bánh mì, rice and noodle dishes — with photos and today's prices.",
        tint = Color(0xFFF7EBEB)
    ),
    ADD_ONS(
        title = "Order it your way",
        body = "Pick sizes and extras on any dish. The price updates as you choose, so there are no surprises.",
        tint = Color(0xFFE8FBE8)
    ),
    PICKUP(
        title = "Choose your pickup time",
        body = "Order ahead for today, pick a time slot, pay in the app and skip the queue when you arrive.",
        tint = Color(0xFFF9F9F9)
    ),
    REWARDS(
        title = "Earn points, get vouchers",
        body = "Every order adds points. Turn them into vouchers and spend them at checkout on your next one.",
        tint = Color(0xFFF7EBEB)
    )
}

@Composable
private fun SlideBody(slide: Slide) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Surface(
            shape = RoundedCornerShape(28.dp),
            color = slide.tint,
            modifier = Modifier
                .widthIn(max = 340.dp)
                // Decorative: the title and body below say the same thing.
                .clearAndSetSemantics { }
        ) {
            Box(modifier = Modifier.padding(18.dp)) {
                when (slide) {
                    Slide.MENU -> MenuArt()
                    Slide.ADD_ONS -> AddOnsArt()
                    Slide.PICKUP -> PickupArt()
                    Slide.REWARDS -> RewardsArt()
                }
            }
        }

        Spacer(modifier = Modifier.height(28.dp))

        Text(
            text = slide.title,
            fontSize = 26.sp,
            fontWeight = FontWeight.Bold,
            color = AppColors.TextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = slide.body,
            fontSize = 16.sp,
            color = AppColors.BarIcon,
            textAlign = TextAlign.Center,
            modifier = Modifier.widthIn(max = 420.dp)
        )
    }
}

// MARK: slide art
//
// The dish names, prices and times below are illustrative content for the preview cards,
// not live data.

/** The category illustrations the iOS menu already ships, copied into `res/drawable`. */
@Composable
private fun MenuArt() {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            CategoryTile(R.drawable.ic_pho_categories, "Phở")
            CategoryTile(R.drawable.ic_banhmi_categories, "Bánh Mì")
        }
        Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            CategoryTile(R.drawable.ic_ricedishes_categories, "Rice")
            CategoryTile(R.drawable.ic_drink_categories, "Drinks")
        }
    }
}

@Composable
private fun CategoryTile(drawable: Int, label: String) {
    Card(modifier = Modifier.size(width = 108.dp, height = 96.dp)) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Image(
                painter = painterResource(drawable),
                contentDescription = null,
                modifier = Modifier.size(52.dp)
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = label,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.TextPrimary
            )
        }
    }
}

/** Mirrors an add-on group on the product screen: a required group with priced options. */
@Composable
private fun AddOnsArt() {
    Card {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Choose your size",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary,
                    modifier = Modifier.weight(1f)
                )
                Surface(shape = CircleShape, color = AppColors.Primary) {
                    Text(
                        text = "Required",
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                    )
                }
            }
            OptionRow("Regular", price = null, selected = false)
            OptionRow("Large", price = "+$3.00", selected = true)
            OptionRow("Extra beef", price = "+$4.50", selected = false)
        }
    }
}

@Composable
private fun OptionRow(label: String, price: String?, selected: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Icon(
            imageVector = if (selected) Icons.Filled.CheckCircle else Icons.Outlined.Circle,
            contentDescription = null,
            tint = if (selected) AppColors.Primary else AppColors.Divider,
            modifier = Modifier.size(17.dp)
        )
        Text(
            text = label,
            fontSize = 13.sp,
            color = AppColors.TextPrimary,
            modifier = Modifier.weight(1f)
        )
        if (price != null) {
            Text(
                text = price,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = AppColors.BarIcon
            )
        }
    }
}

/** Mirrors the checkout pickup step, which offers same-day slots only. */
@Composable
private fun PickupArt() {
    Card {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.Schedule,
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(18.dp)
                )
                Text(
                    text = "Pickup today",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary
                )
            }
            // Scrolls rather than clips: three full times are a tight fit on a narrow
            // screen or at a large font scale, and the real picker scrolls too.
            Row(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.horizontalScroll(rememberScrollState())
            ) {
                TimeChip("11:30 AM", selected = false)
                TimeChip("12:00 PM", selected = true)
                TimeChip("12:30 PM", selected = false)
            }
        }
    }
}

@Composable
private fun TimeChip(label: String, selected: Boolean) {
    Surface(
        shape = CircleShape,
        color = if (selected) AppColors.Primary else AppColors.Surface,
        border = if (selected) null else BorderStroke(1.dp, AppColors.Divider)
    ) {
        Text(
            text = label,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (selected) Color.White else AppColors.BarIcon,
            // A time never wraps: "12:30 PM" was dropping "PM" onto a second line and
            // pushing that chip out of line with the other two.
            maxLines = 1,
            softWrap = false,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 8.dp)
        )
    }
}

/** Mirrors the points balance and the voucher rows on the checkout sheet. */
@Composable
private fun RewardsArt() {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Card {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.Star,
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(18.dp)
                )
                Text(
                    text = "320 points",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.TextPrimary,
                    modifier = Modifier.weight(1f)
                )
                Text(
                    text = "Redeem",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = AppColors.Primary
                )
            }
        }
        Card {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "$5 voucher",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.Primary
                    )
                    Text(
                        text = "Applied at checkout",
                        fontSize = 11.sp,
                        color = AppColors.BarIcon
                    )
                }
                Icon(
                    imageVector = Icons.Filled.CardGiftcard,
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(22.dp)
                )
            }
        }
    }
}

@Composable
private fun Card(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = AppColors.Surface,
        shadowElevation = 3.dp,
        modifier = modifier,
        content = content
    )
}

@Composable
private fun PageDots(current: Int, count: Int) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 24.dp)
            .clearAndSetSemantics { },
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        repeat(count) { index ->
            val width by animateDpAsState(
                targetValue = if (index == current) 22.dp else 8.dp,
                label = "dot"
            )
            Box(
                modifier = Modifier
                    .padding(horizontal = 4.dp)
                    .size(width = width, height = 8.dp)
                    .clip(CircleShape)
                    .background(if (index == current) AppColors.Primary else AppColors.Divider)
            )
        }
    }
}

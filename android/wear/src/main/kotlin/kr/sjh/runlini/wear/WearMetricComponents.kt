package kr.sjh.runlini.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

internal object RunliniWearColors {
    val Black = Color(0xFF000000)
    val Chalk = Color(0xFFF5F5F0)
    val Muted = Color(0xFF9A9A92)
    val Border = Color(0xFF2A2A27)
    val VoltGreen = Color(0xFFB6FF00)
    val ElectricRed = Color(0xFFFF2D55)
    val Cyan = Color(0xFF4AE2FF)
}

@Composable
internal fun RunliniWearTheme(content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(RunliniWearColors.Black),
    ) {
        content()
    }
}

@Composable
internal fun WearCircleButton(
    label: String,
    color: Color,
    textColor: Color,
    modifier: Modifier = Modifier,
    size: Dp = 104.dp,
    icon: WearRunButtonIcon? = null,
    labelFontSize: TextUnit = 18.sp,
    onClick: () -> Unit,
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(color)
            .border(3.dp, RunliniWearColors.Black, CircleShape)
            .semantics { contentDescription = label }
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        if (icon != null) {
            WearRunIconGlyph(
                icon = icon,
                color = textColor,
                modifier = Modifier.size(if (size < 90.dp) 30.dp else 36.dp),
            )
        } else {
            Text(
                text = label,
                color = textColor,
                fontSize = labelFontSize,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
internal fun WearActionButton(
    label: String,
    color: Color,
    textColor: Color,
    modifier: Modifier = Modifier,
    height: Dp = 44.dp,
    icon: WearRunButtonIcon? = null,
    onClick: () -> Unit,
) {
    Box(
        modifier = modifier
            .height(height)
            .clip(RoundedCornerShape(2.dp))
            .background(color)
            .semantics { contentDescription = label }
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
        if (icon != null) {
            WearRunIconGlyph(
                icon = icon,
                color = textColor,
                modifier = Modifier.size(if (height < 34.dp) 16.dp else 18.dp),
            )
        } else {
            Text(
                text = label,
                color = textColor,
                fontSize = 14.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
internal fun WearCompactMetric(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    valueColor: Color = RunliniWearColors.Chalk,
) {
    val labelSize = if (label.length >= 5) 8.sp else 9.sp
    Column(
        modifier = modifier
            .height(44.dp)
            .border(2.dp, RunliniWearColors.Border, RoundedCornerShape(2.dp))
            .padding(horizontal = 6.dp, vertical = 5.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Muted,
            fontSize = labelSize,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            text = value,
            color = valueColor,
            fontSize = 13.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
internal fun WearPrimaryMetric(
    label: String,
    value: String,
    valueColor: Color,
    modifier: Modifier = Modifier,
    profile: WearLayoutProfile = WearLayoutProfile.Compact,
) {
    val valueSize = if (profile == WearLayoutProfile.Compact) 38.sp else 44.sp
    val labelSize = if (profile == WearLayoutProfile.Compact) 10.sp else 11.sp
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Muted,
            fontSize = labelSize,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
        )
        Text(
            text = value,
            color = valueColor,
            fontSize = valueSize,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

internal object WearDistanceHeroTypography {
    fun valueSizeSp(value: String, profile: WearLayoutProfile): Int {
        return when (profile) {
            WearLayoutProfile.Compact -> when {
                value.length <= 4 -> 38
                value.length <= 5 -> 34
                else -> 30
            }
            WearLayoutProfile.Regular -> when {
                value.length <= 4 -> 44
                value.length <= 5 -> 39
                else -> 34
            }
        }
    }

    fun unitSizeSp(profile: WearLayoutProfile): Int {
        return if (profile == WearLayoutProfile.Compact) 16 else 18
    }
}

@Composable
internal fun WearDistanceHeroMetric(
    label: String,
    value: String,
    unit: String,
    valueColor: Color,
    modifier: Modifier = Modifier,
    profile: WearLayoutProfile = WearLayoutProfile.Compact,
) {
    val valueSize = WearDistanceHeroTypography.valueSizeSp(value, profile)
    val unitSize = WearDistanceHeroTypography.unitSizeSp(profile)
    val labelSize = if (profile == WearLayoutProfile.Compact) 10.sp else 11.sp
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Muted,
            fontSize = labelSize,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
        )
        Row(
            horizontalArrangement = Arrangement.spacedBy(5.dp),
            verticalAlignment = Alignment.Bottom,
        ) {
            Text(
                text = value,
                color = valueColor,
                fontSize = valueSize.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
                maxLines = 1,
                softWrap = false,
            )
            Text(
                text = unit,
                color = valueColor,
                fontSize = unitSize.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
                maxLines = 1,
                softWrap = false,
                modifier = Modifier.padding(
                    bottom = if (profile == WearLayoutProfile.Compact) 5.dp else 7.dp,
                ),
            )
        }
    }
}

@Composable
internal fun WearStatusPill(
    label: String,
    color: Color,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier
            .border(2.dp, color, RoundedCornerShape(50))
            .padding(horizontal = 9.dp, vertical = 3.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            color = color,
            fontSize = 10.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
internal fun WearPageIndicator(
    pageCount: Int,
    selectedIndex: Int,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        repeat(pageCount) { index ->
            val selected = index == selectedIndex
            Box(
                modifier = Modifier
                    .size(if (selected) 6.dp else 4.dp)
                    .clip(CircleShape)
                    .background(
                        if (selected) {
                            RunliniWearColors.VoltGreen
                        } else {
                            RunliniWearColors.Border
                        },
                    ),
            )
        }
    }
}

internal fun recordRaceColor(status: WearRecordRaceStatus?): Color {
    return when (status) {
        WearRecordRaceStatus.Ahead -> RunliniWearColors.VoltGreen
        WearRecordRaceStatus.Behind,
        WearRecordRaceStatus.OffRoute -> RunliniWearColors.ElectricRed
        WearRecordRaceStatus.Level -> RunliniWearColors.Chalk
        WearRecordRaceStatus.Unavailable, null -> RunliniWearColors.Muted
    }
}

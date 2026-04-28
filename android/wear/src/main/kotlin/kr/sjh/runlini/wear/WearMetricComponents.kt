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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
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
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(108.dp)
            .clip(CircleShape)
            .background(color)
            .border(3.dp, RunliniWearColors.Black, CircleShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            color = textColor,
            fontSize = 18.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 2,
        )
    }
}

@Composable
internal fun WearActionButton(
    label: String,
    color: Color,
    textColor: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit,
) {
    Box(
        modifier = modifier
            .height(46.dp)
            .clip(RoundedCornerShape(2.dp))
            .background(color)
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp),
        contentAlignment = Alignment.Center,
    ) {
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

@Composable
internal fun WearMetricTile(
    label: String,
    value: String,
    modifier: Modifier = Modifier,
    valueColor: Color = RunliniWearColors.Chalk,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(42.dp)
            .border(2.dp, RunliniWearColors.Border, RoundedCornerShape(2.dp))
            .padding(horizontal = 11.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Muted,
            fontSize = 10.sp,
            fontWeight = FontWeight.Black,
            maxLines = 1,
        )
        Text(
            text = value,
            color = valueColor,
            fontSize = 16.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.End,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Composable
internal fun WearHeroMetric(
    label: String,
    value: String,
    valueColor: Color,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .border(3.dp, valueColor, RoundedCornerShape(2.dp))
            .padding(horizontal = 10.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Muted,
            fontSize = 10.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
        )
        Text(
            text = value,
            color = valueColor,
            fontSize = 34.sp,
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

internal fun ghostColor(status: WearGhostStatus?): Color {
    return when (status) {
        WearGhostStatus.Ahead -> RunliniWearColors.VoltGreen
        WearGhostStatus.Behind,
        WearGhostStatus.OffRoute -> RunliniWearColors.ElectricRed
        WearGhostStatus.Level -> RunliniWearColors.Chalk
        WearGhostStatus.Unavailable, null -> RunliniWearColors.Muted
    }
}

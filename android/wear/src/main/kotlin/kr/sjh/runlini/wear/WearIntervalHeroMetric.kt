package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

internal object WearIntervalHeroTypography {
    fun valueSizeSp(value: String, profile: WearLayoutProfile): Int {
        return when (profile) {
            WearLayoutProfile.Compact -> when {
                value.length <= 3 -> 48
                value.length <= 5 -> 42
                else -> 36
            }
            WearLayoutProfile.Regular -> when {
                value.length <= 3 -> 56
                value.length <= 5 -> 48
                else -> 42
            }
        }
    }

    fun labelSizeSp(profile: WearLayoutProfile): Int {
        return if (profile == WearLayoutProfile.Compact) 10 else 11
    }
}

@Composable
internal fun WearIntervalHeroMetric(
    label: String,
    value: String,
    valueColor: Color,
    modifier: Modifier = Modifier,
    profile: WearLayoutProfile = WearLayoutProfile.Compact,
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Muted,
            fontSize = WearIntervalHeroTypography.labelSizeSp(profile).sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            softWrap = false,
        )
        Text(
            text = value,
            color = valueColor,
            fontSize = WearIntervalHeroTypography.valueSizeSp(value, profile).sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            softWrap = false,
        )
    }
}

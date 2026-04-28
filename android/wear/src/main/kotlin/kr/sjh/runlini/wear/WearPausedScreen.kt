package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearPausedScreen(
    state: WearRunState,
    onResume: () -> Unit,
    onStop: () -> Unit,
) {
    WearRunPageFrame(
        verticalArrangement = Arrangement.Center,
    ) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        val spacerHeight = if (compact) 5.dp else 8.dp
        val buttonHeight = if (compact) 32.dp else 38.dp

        Text(
            text = "일시정지",
            color = RunliniWearColors.Chalk,
            fontSize = if (compact) 19.sp else 22.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(spacerHeight))
        WearPrimaryMetric(
            label = "시간",
            value = WearRunFormatters.elapsed(state.elapsedMs),
            valueColor = RunliniWearColors.Chalk,
            profile = spec.profile,
        )
        Spacer(modifier = Modifier.height(spacerHeight))
        WearCompactMetric(
            label = "거리",
            value = WearRunFormatters.distance(state.distanceM),
            modifier = Modifier.fillMaxWidth(),
            valueColor = RunliniWearColors.VoltGreen,
        )
        Spacer(modifier = Modifier.height(if (compact) 7.dp else 10.dp))
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
        ) {
            WearActionButton(
                label = "재개",
                color = RunliniWearColors.VoltGreen,
                textColor = RunliniWearColors.Black,
                modifier = Modifier.weight(1f),
                height = buttonHeight,
                onClick = onResume,
            )
            Spacer(modifier = Modifier.width(6.dp))
            WearActionButton(
                label = "종료",
                color = RunliniWearColors.ElectricRed,
                textColor = RunliniWearColors.Chalk,
                modifier = Modifier.weight(1f),
                height = buttonHeight,
                onClick = onStop,
            )
        }
    }
}

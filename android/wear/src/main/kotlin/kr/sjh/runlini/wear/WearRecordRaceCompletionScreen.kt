package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearRecordRaceCompletionScreen(
    onStop: () -> Unit,
    onContinue: () -> Unit,
) {
    WearRunPageFrame(verticalArrangement = Arrangement.SpaceBetween) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        Text(
            text = "기록 레이스 완료",
            color = RunliniWearColors.VoltGreen,
            fontSize = if (compact) 20.sp else 24.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )
        Text(
            text = "코스를 마쳤어요",
            color = RunliniWearColors.Chalk,
            fontSize = if (compact) 13.sp else 15.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(
                space = if (compact) 12.dp else 16.dp,
                alignment = Alignment.CenterHorizontally,
            ),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            WearCircleButton(
                label = "계속",
                color = RunliniWearColors.Chalk,
                textColor = RunliniWearColors.Black,
                size = if (compact) 62.dp else 72.dp,
                onClick = onContinue,
            )
            WearCircleButton(
                label = "종료",
                color = RunliniWearColors.ElectricRed,
                textColor = RunliniWearColors.Chalk,
                size = if (compact) 62.dp else 72.dp,
                onClick = onStop,
            )
        }
        Spacer(modifier = Modifier.height(if (compact) 10.dp else 14.dp))
    }
}

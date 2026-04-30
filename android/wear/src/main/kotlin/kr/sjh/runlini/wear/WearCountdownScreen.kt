package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearCountdownScreen(state: WearRunState) {
    val model = WearCountdownModelBuilder.from(state)
    WearRunPageFrame(
        verticalArrangement = Arrangement.Center,
    ) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = model.label,
                color = RunliniWearColors.Muted,
                fontSize = if (compact) 17.sp else 19.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
            Text(
                text = model.remainingSeconds,
                color = RunliniWearColors.VoltGreen,
                fontSize = if (compact) 92.sp else 108.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }
    }
}

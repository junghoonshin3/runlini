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
internal fun WearCompletionFeedbackScreen(state: WearRunState) {
    val model = WearCompletionFeedbackModelBuilder.from(state)
    WearRunPageFrame(
        verticalArrangement = Arrangement.Center,
    ) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        val color = if (model.isDestructive) {
            RunliniWearColors.ElectricRed
        } else {
            RunliniWearColors.VoltGreen
        }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = model.label,
                color = color,
                fontSize = if (compact) 30.sp else 36.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
                maxLines = 1,
            )
        }
    }
}

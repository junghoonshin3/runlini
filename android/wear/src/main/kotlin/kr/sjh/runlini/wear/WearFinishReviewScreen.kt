package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearFinishReviewScreen(
    state: WearRunState,
    onSave: () -> Unit,
    onDiscard: () -> Unit,
) {
    val summary = WearReviewSummaryModelBuilder.from(state)
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 14.dp, vertical = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        item {
            Text(
                text = "REVIEW",
                color = RunliniWearColors.Chalk,
                fontSize = 22.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }
        item { Spacer(modifier = Modifier.height(8.dp)) }
        item {
            WearHeroMetric(
                label = "TIME",
                value = summary.elapsed,
                valueColor = RunliniWearColors.Chalk,
            )
        }
        item { Spacer(modifier = Modifier.height(8.dp)) }
        item { WearMetricTile(label = "DIST", value = summary.distance) }
        item { Spacer(modifier = Modifier.height(6.dp)) }
        item { WearMetricTile(label = "AVG", value = summary.averagePace) }
        item { Spacer(modifier = Modifier.height(6.dp)) }
        item { WearMetricTile(label = "CAL", value = summary.calories) }
        summary.ghostResult?.let { ghostResult ->
            item { Spacer(modifier = Modifier.height(6.dp)) }
            item {
                WearMetricTile(
                    label = "GHOST",
                    value = ghostResult,
                    valueColor = ghostColor(state.ghostFrame?.status),
                )
            }
        }
        summary.pendingLabel?.let { pendingLabel ->
            item { Spacer(modifier = Modifier.height(6.dp)) }
            item {
                Text(
                    text = pendingLabel,
                    color = RunliniWearColors.VoltGreen,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Black,
                    textAlign = TextAlign.Center,
                )
            }
        }
        item { Spacer(modifier = Modifier.height(10.dp)) }
        item {
            WearActionButton(
                label = "SAVE",
                color = RunliniWearColors.VoltGreen,
                textColor = RunliniWearColors.Black,
                modifier = Modifier.fillMaxWidth(),
                onClick = onSave,
            )
        }
        item { Spacer(modifier = Modifier.height(8.dp)) }
        item {
            WearActionButton(
                label = "DISCARD",
                color = RunliniWearColors.ElectricRed,
                textColor = RunliniWearColors.Chalk,
                modifier = Modifier.fillMaxWidth(),
                onClick = onDiscard,
            )
        }
    }
}

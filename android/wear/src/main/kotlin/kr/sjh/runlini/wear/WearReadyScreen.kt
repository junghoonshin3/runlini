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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearReadyScreen(
    state: WearRunState,
    onStart: () -> Unit,
    onGhostStart: () -> Unit,
    onRetryPending: () -> Unit,
) {
    val model = WearReadyScreenModelBuilder.from(state)
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 18.dp, vertical = 18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        item {
            Text(
                text = "RUNLINI",
                color = RunliniWearColors.Chalk,
                fontSize = 28.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }
        item { Spacer(modifier = Modifier.height(8.dp)) }
        item {
            Text(
                text = model.statusLabel,
                color = if (model.isError) {
                    RunliniWearColors.ElectricRed
                } else {
                    RunliniWearColors.Muted
                },
                fontSize = 12.sp,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        model.ghostLabel?.let { ghostLabel ->
            item { Spacer(modifier = Modifier.height(10.dp)) }
            item {
                WearMetricTile(
                    label = "GHOST",
                    value = ghostLabel,
                    valueColor = RunliniWearColors.VoltGreen,
                )
            }
        }
        item { Spacer(modifier = Modifier.height(14.dp)) }
        item {
            WearCircleButton(
                label = model.primaryLabel,
                color = RunliniWearColors.VoltGreen,
                textColor = RunliniWearColors.Black,
                onClick = if (model.usesGhostPrimary) onGhostStart else onStart,
            )
        }
        model.secondaryLabel?.let { secondaryLabel ->
            item { Spacer(modifier = Modifier.height(10.dp)) }
            item {
                WearActionButton(
                    label = secondaryLabel,
                    color = RunliniWearColors.Chalk,
                    textColor = RunliniWearColors.Black,
                    modifier = Modifier.fillMaxWidth(),
                    onClick = onStart,
                )
            }
        }
        model.pendingLabel?.let { pendingLabel ->
            item { Spacer(modifier = Modifier.height(12.dp)) }
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
        model.retryLabel?.let { retryLabel ->
            item { Spacer(modifier = Modifier.height(8.dp)) }
            item {
                WearActionButton(
                    label = retryLabel,
                    color = RunliniWearColors.Chalk,
                    textColor = RunliniWearColors.Black,
                    modifier = Modifier.fillMaxWidth(),
                    onClick = onRetryPending,
                )
            }
        }
    }
}

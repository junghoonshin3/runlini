package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
    WearRunPageFrame(
        verticalArrangement = Arrangement.SpaceBetween,
    ) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        val primarySize = if (compact) 76.dp else 94.dp
        val actionHeight = if (compact) 30.dp else 34.dp
        val pendingLabel = readyPendingLabel(state)
        val hasSecondaryAction = model.secondaryLabel != null
        val hasRetryAction = model.retryLabel != null

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = "RUNLINI",
                color = RunliniWearColors.Chalk,
                fontSize = if (compact) 19.sp else 23.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
        }

        WearCircleButton(
            label = model.primaryLabel.replace('\n', ' '),
            color = RunliniWearColors.VoltGreen,
            textColor = RunliniWearColors.Black,
            size = primarySize,
            onClick = if (model.usesGhostPrimary) onGhostStart else onStart,
        )

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                WearStatusPill(
                    label = readyStatusLabel(model),
                    color = if (model.isError) {
                        RunliniWearColors.ElectricRed
                    } else {
                        RunliniWearColors.Muted
                    },
                    modifier = if (pendingLabel != null) Modifier.weight(1f) else Modifier,
                )
                pendingLabel?.let {
                    Spacer(modifier = Modifier.width(5.dp))
                    WearStatusPill(
                        label = it,
                        color = RunliniWearColors.VoltGreen,
                        modifier = Modifier.weight(1f),
                    )
                }
            }

            if (hasSecondaryAction || hasRetryAction) {
                Spacer(modifier = Modifier.height(if (compact) 5.dp else 7.dp))
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
            ) {
                model.secondaryLabel?.let { secondaryLabel ->
                    WearActionButton(
                        label = secondaryLabel,
                        color = RunliniWearColors.Chalk,
                        textColor = RunliniWearColors.Black,
                        modifier = if (hasRetryAction) Modifier.weight(1f) else Modifier.fillMaxWidth(),
                        height = actionHeight,
                        onClick = onStart,
                    )
                }
                if (hasSecondaryAction && hasRetryAction) {
                    Spacer(modifier = Modifier.width(6.dp))
                }
                model.retryLabel?.let {
                    WearActionButton(
                        label = "재전송",
                        color = RunliniWearColors.Chalk,
                        textColor = RunliniWearColors.Black,
                        modifier = if (hasSecondaryAction) Modifier.weight(1f) else Modifier.fillMaxWidth(),
                        height = actionHeight,
                        onClick = onRetryPending,
                    )
                }
            }
        }
    }
}

private fun readyStatusLabel(model: WearReadyScreenModel): String {
    return when {
        model.isError -> "오류"
        model.usesGhostPrimary -> model.ghostLabel ?: "고스트"
        model.statusLabel == "준비 완료" -> "준비"
        else -> model.statusLabel
    }
}

private fun readyPendingLabel(state: WearRunState): String? {
    return if (state.pendingDraftCount > 0) {
        "대기 ${state.pendingDraftCount}"
    } else {
        null
    }
}

package kr.sjh.runlini.wear

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
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
internal fun WearFinishReviewScreen(
    state: WearRunState,
    onSave: () -> Unit,
    onDiscard: () -> Unit,
) {
    val summary = WearReviewSummaryModelBuilder.from(state)
    WearRunPageFrame(
        verticalArrangement = Arrangement.SpaceBetween,
    ) { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        val gap = if (compact) 4.dp else 6.dp
        val actionHeight = if (compact) 30.dp else 36.dp
        val ghostLabel = finishGhostLabel(state)
        val pendingLabel = finishPendingLabel(state)
        val hasGhostLabel = ghostLabel != null
        val hasPendingLabel = pendingLabel != null

        Text(
            text = "완료",
            color = RunliniWearColors.Chalk,
            fontSize = if (compact) 18.sp else 21.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )

        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(gap),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                WearCompactMetric(
                    label = "거리",
                    value = summary.distance,
                    modifier = Modifier.weight(1f),
                    valueColor = RunliniWearColors.VoltGreen,
                )
                WearCompactMetric(
                    label = "시간",
                    value = summary.elapsed,
                    modifier = Modifier.weight(1f),
                )
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                WearCompactMetric(
                    label = "평균 페이스",
                    value = summary.averagePace,
                    modifier = Modifier.weight(1f),
                )
                WearCompactMetric(
                    label = if (state.averageCadenceSpm == null) "칼로리" else "케이던스",
                    value = if (state.averageCadenceSpm == null) {
                        summary.calories
                    } else {
                        summary.averageCadence
                    },
                    modifier = Modifier.weight(1f),
                )
            }
            if (hasGhostLabel || hasPendingLabel) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    ghostLabel?.let {
                        WearStatusPill(
                            label = it,
                            color = ghostColor(state.ghostFrame?.status),
                            modifier = if (hasPendingLabel) Modifier.weight(1f) else Modifier,
                        )
                    }
                    if (hasGhostLabel && hasPendingLabel) {
                        Spacer(modifier = Modifier.width(5.dp))
                    }
                    pendingLabel?.let {
                        WearStatusPill(
                            label = it,
                            color = RunliniWearColors.VoltGreen,
                            modifier = if (hasGhostLabel) Modifier.weight(1f) else Modifier,
                        )
                    }
                }
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
        ) {
            WearActionButton(
                label = "저장",
                color = RunliniWearColors.VoltGreen,
                textColor = RunliniWearColors.Black,
                modifier = Modifier.weight(1f),
                height = actionHeight,
                onClick = onSave,
            )
            Spacer(modifier = Modifier.width(6.dp))
            WearActionButton(
                label = "삭제",
                color = RunliniWearColors.ElectricRed,
                textColor = RunliniWearColors.Chalk,
                modifier = Modifier.weight(1f),
                height = actionHeight,
                onClick = onDiscard,
            )
        }
    }
}

private fun finishGhostLabel(state: WearRunState): String? {
    if (!state.isGhostRun) return null
    val frame = state.ghostFrame
    return when (frame?.status) {
        WearGhostStatus.Level -> "고스트 접전"
        WearGhostStatus.OffRoute -> "경로 이탈"
        WearGhostStatus.Unavailable,
        null -> "고스트 --"
        WearGhostStatus.Ahead,
        WearGhostStatus.Behind -> "고스트 ${WearRunFormatters.ghostGap(frame)}"
    }
}

private fun finishPendingLabel(state: WearRunState): String? {
    return if (state.pendingDraftCount > 0) {
        "대기 ${state.pendingDraftCount}"
    } else {
        null
    }
}

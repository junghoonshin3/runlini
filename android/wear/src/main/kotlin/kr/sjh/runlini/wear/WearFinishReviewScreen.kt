package kr.sjh.runlini.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
    WearScrollableReviewFrame { spec ->
        val compact = spec.profile == WearLayoutProfile.Compact
        val titleSize = if (compact) 22.sp else 26.sp
        val actionHeight = if (compact) 34.dp else 38.dp

        Text(
            text = "완료",
            color = RunliniWearColors.Chalk,
            fontSize = titleSize,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(modifier = Modifier.height(if (compact) 8.dp else 10.dp))

        WearReviewHero(summary)
        Spacer(modifier = Modifier.height(8.dp))

        WearReviewMetricGrid(metrics = summary.detailMetrics)
        summary.ghostResult?.let { result ->
            Spacer(modifier = Modifier.height(8.dp))
            WearReviewStatusRow(
                label = "고스트",
                value = result,
                color = ghostColor(state.ghostFrame?.status),
            )
        }

        Spacer(modifier = Modifier.height(if (compact) 10.dp else 12.dp))
        WearActionButton(
            label = "저장",
            color = RunliniWearColors.VoltGreen,
            textColor = RunliniWearColors.Black,
            modifier = Modifier.fillMaxWidth(),
            height = actionHeight,
            onClick = onSave,
        )
        Spacer(modifier = Modifier.height(6.dp))
        WearActionButton(
            label = "삭제",
            color = RunliniWearColors.ElectricRed,
            textColor = RunliniWearColors.Chalk,
            modifier = Modifier.fillMaxWidth(),
            height = actionHeight,
            onClick = onDiscard,
        )
    }
}

@Composable
private fun WearScrollableReviewFrame(content: @Composable (WearRunLayoutSpec) -> Unit) {
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(RunliniWearColors.Black),
    ) {
        val profile = WearRunLayoutModel.profileFor(
            widthDp = maxWidth.value.toInt(),
            heightDp = maxHeight.value.toInt(),
        )
        val compact = profile == WearLayoutProfile.Compact
        val spec = WearRunLayoutSpec(
            profile = profile,
            horizontalPadding = if (compact) maxWidth * 0.13f else maxWidth * 0.11f,
            verticalPadding = if (compact) maxHeight * 0.08f else maxHeight * 0.09f,
            pageIndicatorInset = 0.dp,
        )
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(
                    start = spec.horizontalPadding,
                    end = spec.horizontalPadding,
                    top = spec.verticalPadding,
                    bottom = spec.verticalPadding,
                ),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            content(spec)
        }
    }
}

@Composable
private fun WearReviewHero(summary: WearReviewSummaryModel) {
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
    Spacer(modifier = Modifier.height(6.dp))
    WearCompactMetric(
        label = "평균 페이스",
        value = summary.averagePace,
        modifier = Modifier.fillMaxWidth(),
    )
}

@Composable
private fun WearReviewMetricGrid(metrics: List<WearReviewMetric>) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        metrics.chunked(2).forEach { rowMetrics ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                rowMetrics.forEach { metric ->
                    WearCompactMetric(
                        label = metric.label,
                        value = metric.value,
                        modifier = Modifier.weight(1f),
                    )
                }
                if (rowMetrics.size == 1) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun WearReviewStatusRow(
    label: String,
    value: String,
    color: androidx.compose.ui.graphics.Color,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .border(2.dp, color, RoundedCornerShape(2.dp))
            .padding(horizontal = 8.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Muted,
            fontSize = 9.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = value,
            color = color,
            fontSize = 12.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
        )
    }
}

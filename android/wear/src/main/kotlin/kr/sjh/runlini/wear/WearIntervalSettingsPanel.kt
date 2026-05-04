package kr.sjh.runlini.wear

import androidx.compose.foundation.border
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text

@Composable
internal fun WearIntervalSettingsPanel(
    workout: WearIntervalWorkout,
    onWorkoutChange: (WearIntervalWorkout) -> Unit,
) {
    val normalized = WearIntervalQuickSettings.normalize(workout)
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        WearSettingToggleRow(
            label = "인터벌",
            checked = normalized.enabled,
            onCheckedChange = { enabled ->
                onWorkoutChange(normalized.copy(enabled = enabled))
            },
        )
        Spacer(modifier = Modifier.height(5.dp))
        WearIntervalTargetSettingRow(
            label = "질주",
            target = normalized.work,
            onToggleType = {
                onWorkoutChange(
                    normalized.copy(
                        work = WearIntervalQuickSettings.toggleTargetType(
                            normalized.work,
                            isWork = true,
                        ),
                    ),
                )
            },
            onStep = { delta ->
                onWorkoutChange(
                    normalized.copy(
                        work = WearIntervalQuickSettings.stepTarget(
                            normalized.work,
                            isWork = true,
                            delta = delta,
                        ),
                    ),
                )
            },
        )
        Spacer(modifier = Modifier.height(5.dp))
        WearIntervalTargetSettingRow(
            label = "휴식",
            target = normalized.recovery,
            onToggleType = {
                onWorkoutChange(
                    normalized.copy(
                        recovery = WearIntervalQuickSettings.toggleTargetType(
                            normalized.recovery,
                            isWork = false,
                        ),
                    ),
                )
            },
            onStep = { delta ->
                onWorkoutChange(
                    normalized.copy(
                        recovery = WearIntervalQuickSettings.stepTarget(
                            normalized.recovery,
                            isWork = false,
                            delta = delta,
                        ),
                    ),
                )
            },
        )
        Spacer(modifier = Modifier.height(5.dp))
        WearIntervalRepeatSettingRow(
            repeatCount = normalized.repeatCount,
            onStep = { delta ->
                onWorkoutChange(
                    normalized.copy(
                        repeatCount = WearIntervalQuickSettings.stepRepeat(
                            normalized.repeatCount,
                            delta,
                        ),
                    ),
                )
            },
        )
        Spacer(modifier = Modifier.height(7.dp))
    }
}

@Composable
private fun WearIntervalTargetSettingRow(
    label: String,
    target: WearIntervalTarget,
    onToggleType: () -> Unit,
    onStep: (Int) -> Unit,
) {
    WearIntervalStepperRow(
        label = label,
        value = WearIntervalFormatters.target(target),
        mode = if (target.type == WearIntervalTargetType.Distance) "거리" else "시간",
        onModeClick = onToggleType,
        onMinus = { onStep(-1) },
        onPlus = { onStep(1) },
    )
}

@Composable
private fun WearIntervalRepeatSettingRow(
    repeatCount: Int,
    onStep: (Int) -> Unit,
) {
    WearIntervalStepperRow(
        label = "반복",
        value = "${repeatCount}회",
        mode = null,
        onModeClick = {},
        onMinus = { onStep(-1) },
        onPlus = { onStep(1) },
    )
}

@Composable
private fun WearIntervalStepperRow(
    label: String,
    value: String,
    mode: String?,
    onModeClick: () -> Unit,
    onMinus: () -> Unit,
    onPlus: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(34.dp)
            .clip(RoundedCornerShape(2.dp))
            .border(2.dp, RunliniWearColors.Border, RoundedCornerShape(2.dp))
            .padding(horizontal = 7.dp),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Chalk,
            fontSize = 11.sp,
            fontWeight = FontWeight.Black,
            maxLines = 1,
        )
        mode?.let {
            WearStatusPill(
                label = it,
                color = RunliniWearColors.VoltGreen,
                modifier = Modifier.clickable(onClick = onModeClick),
            )
        }
        WearMiniStepButton(label = "-", onClick = onMinus)
        Text(
            text = value,
            color = RunliniWearColors.Chalk,
            fontSize = 12.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
        WearMiniStepButton(label = "+", onClick = onPlus)
    }
}

@Composable
private fun WearMiniStepButton(
    label: String,
    onClick: () -> Unit,
) {
    Text(
        text = label,
        color = RunliniWearColors.Black,
        fontSize = 13.sp,
        fontWeight = FontWeight.Black,
        textAlign = TextAlign.Center,
        modifier = Modifier
            .clip(RoundedCornerShape(2.dp))
            .background(RunliniWearColors.VoltGreen)
            .clickable(onClick = onClick)
            .border(2.dp, RunliniWearColors.VoltGreen, RoundedCornerShape(2.dp))
            .padding(horizontal = 8.dp, vertical = 2.dp),
    )
}

package kr.sjh.runlini.wear

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.Text
import kotlin.math.roundToInt

internal object WearVolumeRowLayoutModel {
    const val StepButtonWidthDp = 24
    const val ValueWidthDp = 38
    const val GapDp = 6
    const val MaxValueCharacters = 4

    fun percentLabel(volume: Float): String {
        val safeVolume = WearRunSettingsDefaults.clampVoiceVolume(volume)
        return "${(safeVolume * 100).roundToInt()}%"
    }

    fun fixedControlWidthDp(): Int {
        return (StepButtonWidthDp * 2) + ValueWidthDp + (GapDp * 2)
    }

    fun controlWidthFor(volume: Float): Int {
        percentLabel(volume)
        return fixedControlWidthDp()
    }

    fun valueSlotCanShow(label: String): Boolean {
        return label.length <= MaxValueCharacters
    }
}

@Composable
internal fun WearSettingsScreen(
    settings: WearRunSettings,
    onCountdownEnabledChange: (Boolean) -> Unit,
    onAutoPauseEnabledChange: (Boolean) -> Unit,
    onVibrationEnabledChange: (Boolean) -> Unit,
    onKmAlertEnabledChange: (Boolean) -> Unit,
    onVoiceCueEnabledChange: (Boolean) -> Unit,
    onVoiceCueVolumeChange: (Float) -> Unit,
    onGhostVoiceCueEnabledChange: (Boolean) -> Unit,
    onIntervalWorkoutChange: (WearIntervalWorkout) -> Unit,
) {
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .background(RunliniWearColors.Black),
    ) {
        val spec = WearRunLayoutSpec(
            profile = WearRunLayoutModel.profileFor(
                widthDp = maxWidth.value.toInt(),
                heightDp = maxHeight.value.toInt(),
            ),
            horizontalPadding = maxWidth * 0.12f,
            verticalPadding = maxHeight * 0.06f,
            pageIndicatorInset = 14.dp,
        )
        val compact = spec.profile == WearLayoutProfile.Compact
        androidx.compose.foundation.layout.Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(
                    start = spec.horizontalPadding,
                    end = spec.horizontalPadding,
                    top = spec.verticalPadding,
                    bottom = spec.verticalPadding + spec.pageIndicatorInset,
                ),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = "설정",
                color = RunliniWearColors.Chalk,
                fontSize = if (compact) 19.sp else 23.sp,
                fontWeight = FontWeight.Black,
                textAlign = TextAlign.Center,
            )
            Spacer(modifier = Modifier.height(if (compact) 8.dp else 10.dp))
            WearIntervalSettingsPanel(
                workout = settings.intervalWorkout,
                onWorkoutChange = onIntervalWorkoutChange,
            )
            WearSettingToggleRow(
                label = "카운트다운",
                checked = settings.countdownEnabled,
                onCheckedChange = onCountdownEnabledChange,
            )
            Spacer(modifier = Modifier.height(5.dp))
            WearSettingToggleRow(
                label = "자동 일시정지",
                checked = settings.autoPauseEnabled,
                onCheckedChange = onAutoPauseEnabledChange,
            )
            Spacer(modifier = Modifier.height(5.dp))
            WearSettingToggleRow(
                label = "진동",
                checked = settings.vibrationEnabled,
                onCheckedChange = onVibrationEnabledChange,
            )
            Spacer(modifier = Modifier.height(5.dp))
            WearSettingToggleRow(
                label = "1km 알림",
                checked = settings.kmAlertEnabled,
                onCheckedChange = onKmAlertEnabledChange,
            )
            Spacer(modifier = Modifier.height(5.dp))
            WearSettingToggleRow(
                label = "음성 안내",
                checked = settings.voiceCueEnabled,
                onCheckedChange = onVoiceCueEnabledChange,
            )
            Spacer(modifier = Modifier.height(5.dp))
            WearSettingVolumeRow(
                volume = settings.voiceCueVolume,
                onVolumeChange = onVoiceCueVolumeChange,
            )
            Spacer(modifier = Modifier.height(5.dp))
            WearSettingToggleRow(
                label = "고스트 음성",
                checked = settings.ghostVoiceCueEnabled,
                onCheckedChange = onGhostVoiceCueEnabledChange,
            )
        }
    }
}

@Composable
private fun WearSettingVolumeRow(
    volume: Float,
    onVolumeChange: (Float) -> Unit,
) {
    val safeVolume = WearRunSettingsDefaults.clampVoiceVolume(volume)
    val percentLabel = WearVolumeRowLayoutModel.percentLabel(safeVolume)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(30.dp)
            .clip(RoundedCornerShape(2.dp))
            .border(2.dp, RunliniWearColors.Border, RoundedCornerShape(2.dp))
            .padding(horizontal = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(WearVolumeRowLayoutModel.GapDp.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = "음량",
            color = RunliniWearColors.Chalk,
            fontSize = 12.sp,
            fontWeight = FontWeight.Black,
            maxLines = 1,
            modifier = Modifier.weight(1f),
        )
        WearVolumeStepButton("-") {
            onVolumeChange(safeVolume - WearRunSettingsDefaults.VoiceCueVolumeStep)
        }
        Text(
            text = percentLabel,
            color = RunliniWearColors.VoltGreen,
            fontSize = 11.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
            maxLines = 1,
            modifier = Modifier.width(WearVolumeRowLayoutModel.ValueWidthDp.dp),
        )
        WearVolumeStepButton("+") {
            onVolumeChange(safeVolume + WearRunSettingsDefaults.VoiceCueVolumeStep)
        }
    }
}

@Composable
private fun WearVolumeStepButton(
    label: String,
    onClick: () -> Unit,
) {
    androidx.compose.foundation.layout.Box(
        modifier = Modifier
            .width(WearVolumeRowLayoutModel.StepButtonWidthDp.dp)
            .height(22.dp)
            .clip(RoundedCornerShape(50))
            .border(2.dp, RunliniWearColors.VoltGreen, RoundedCornerShape(50))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.VoltGreen,
            fontSize = 12.sp,
            fontWeight = FontWeight.Black,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
internal fun WearSettingToggleRow(
    label: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(30.dp)
            .clip(RoundedCornerShape(2.dp))
            .border(
                width = 2.dp,
                color = if (checked) RunliniWearColors.VoltGreen else RunliniWearColors.Border,
                shape = RoundedCornerShape(2.dp),
            )
            .clickable { onCheckedChange(!checked) }
            .padding(horizontal = 9.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            color = RunliniWearColors.Chalk,
            fontSize = 12.sp,
            fontWeight = FontWeight.Black,
            maxLines = 1,
        )
        WearStatusPill(
            label = if (checked) "ON" else "OFF",
            color = if (checked) RunliniWearColors.VoltGreen else RunliniWearColors.Muted,
        )
    }
}

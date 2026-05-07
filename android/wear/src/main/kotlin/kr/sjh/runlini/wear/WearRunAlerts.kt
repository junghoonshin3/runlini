package kr.sjh.runlini.wear

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import kotlin.math.floor
import kotlin.math.roundToInt

interface WearRunHaptics {
    fun tick()
}

class AndroidWearRunHaptics(context: Context) : WearRunHaptics {
    private val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val manager = context.getSystemService(VibratorManager::class.java)
        manager?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Vibrator::class.java)
    }

    @Suppress("DEPRECATION")
    override fun tick() {
        val target = vibrator ?: return
        if (!target.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            target.vibrate(
                VibrationEffect.createOneShot(
                    70L,
                    VibrationEffect.DEFAULT_AMPLITUDE,
                ),
            )
        } else {
            target.vibrate(70L)
        }
    }
}

class WearRunAlertController(
    private val haptics: WearRunHaptics,
    private val speech: WearRunSpeech = NoOpWearRunSpeech,
    private val nowMs: () -> Long = { System.currentTimeMillis() },
) {
    private companion object {
        const val OffRouteStableMs = 10_000L
        const val CrossingStableMs = 15_000L
    }

    private var lastAlertedKm: Int = 0
    private var lastIntervalStepLabel: String? = null
    private var ghostCandidateStatus: WearGhostStatus? = null
    private var ghostCandidateSinceMs: Long = 0L
    private var lastStableRaceStatus: WearGhostStatus? = null
    private var offRouteCueSpoken: Boolean = false
    private var returnCueSpoken: Boolean = false
    private var ghostCompletionSpoken: Boolean = false

    fun reset() {
        lastAlertedKm = 0
        lastIntervalStepLabel = null
        ghostCandidateStatus = null
        ghostCandidateSinceMs = 0L
        lastStableRaceStatus = null
        offRouteCueSpoken = false
        returnCueSpoken = false
        ghostCompletionSpoken = false
    }

    fun onRunStarted(settings: WearRunSettings, isGhostRun: Boolean) {
        if (isGhostRun && settings.voiceCueEnabled && settings.ghostVoiceCueEnabled) {
            speech.speak(WearRunVoiceCueFormatter.ghostStart(), settings.voiceCueVolume)
        }
    }

    fun onDistanceChanged(
        distanceM: Double,
        averagePaceSecPerKm: Double?,
        settings: WearRunSettings,
        elapsedMs: Long? = null,
        isGhostRun: Boolean = false,
        ghostFrame: WearGhostFrame? = null,
    ) {
        val currentKm = floor(distanceM / 1000.0).toInt()
        if (currentKm <= 0 || currentKm <= lastAlertedKm) return
        lastAlertedKm = currentKm
        if (settings.vibrationEnabled && settings.kmAlertEnabled) {
            haptics.tick()
        }
        if (settings.voiceCueEnabled && settings.kmAlertEnabled) {
            speech.speak(
                WearRunVoiceCueFormatter.kilometerSummary(
                    kilometer = currentKm,
                    averagePaceSecPerKm = averagePaceSecPerKm,
                    elapsedMs = elapsedMs,
                    ghostGapMs = if (isGhostRun) ghostFrame?.gapForKilometerCue() else null,
                ),
                settings.voiceCueVolume,
            )
        }
    }

    fun onGhostFrame(
        frame: WearGhostFrame?,
        settings: WearRunSettings,
        isGhostRun: Boolean,
    ) {
        if (
            !isGhostRun ||
            !settings.voiceCueEnabled ||
            !settings.ghostVoiceCueEnabled ||
            frame == null ||
            frame.status == WearGhostStatus.Unavailable
        ) {
            return
        }
        val status = frame.status
        val now = nowMs()
        if (ghostCandidateStatus != status) {
            ghostCandidateStatus = status
            ghostCandidateSinceMs = now
            return
        }
        val stableForMs = now - ghostCandidateSinceMs
        if (status == WearGhostStatus.OffRoute) {
            if (!offRouteCueSpoken && stableForMs >= OffRouteStableMs) {
                offRouteCueSpoken = true
                speech.speak("경로를 벗어났어요", settings.voiceCueVolume)
            }
            return
        }
        if (offRouteCueSpoken && !returnCueSpoken && stableForMs >= OffRouteStableMs) {
            returnCueSpoken = true
            speech.speak("경로로 돌아왔어요", settings.voiceCueVolume)
            return
        }
        if (stableForMs < CrossingStableMs) return
        if (status == WearGhostStatus.Level) {
            lastStableRaceStatus = status
            return
        }
        if (status != WearGhostStatus.Ahead && status != WearGhostStatus.Behind) return

        val previousStableStatus = lastStableRaceStatus
        lastStableRaceStatus = status
        if (previousStableStatus == null || previousStableStatus == status) return
        val text = when (status) {
            WearGhostStatus.Ahead -> "고스트를 앞섰어요"
            WearGhostStatus.Behind -> "고스트에게 뒤처졌어요"
            else -> return
        }
        speech.speak(text, settings.voiceCueVolume)
    }

    fun onIntervalFrame(
        frame: WearIntervalFrame?,
        settings: WearRunSettings,
        isGhostRun: Boolean = false,
    ) {
        val label = WearIntervalFormatters.stepLabel(frame?.step)
        if (frame == null || label == lastIntervalStepLabel) return
        lastIntervalStepLabel = label
        if (settings.vibrationEnabled) {
            haptics.tick()
        }
        if (!isGhostRun && settings.voiceCueEnabled) {
            speech.speak(label, settings.voiceCueVolume)
        }
    }

    fun onGhostCompleted(
        settings: WearRunSettings,
        isGhostRun: Boolean,
        frame: WearGhostFrame? = null,
    ) {
        if (isGhostRun && settings.vibrationEnabled) {
            haptics.tick()
        }
        if (
            isGhostRun &&
            !ghostCompletionSpoken &&
            settings.voiceCueEnabled &&
            settings.ghostVoiceCueEnabled
        ) {
            ghostCompletionSpoken = true
            speech.speak(
                WearRunVoiceCueFormatter.ghostCompletion(frame),
                settings.voiceCueVolume,
            )
        }
    }

    fun playVoiceTestCue(volume: Float) {
        speech.speak(
            WearVoiceTestCue.Text,
            WearRunSettingsDefaults.clampVoiceVolume(volume),
        )
    }

    fun shutdown() {
        speech.shutdown()
    }
}

internal object WearRunVoiceCueFormatter {
    fun ghostStart(): String = "고스트런 시작"

    fun kilometerSummary(
        kilometer: Int,
        averagePaceSecPerKm: Double?,
        elapsedMs: Long? = null,
        ghostGapMs: Long? = null,
    ): String {
        val parts = mutableListOf("${kilometer}킬로미터")
        paceSpeech(averagePaceSecPerKm)?.let {
            parts += "평균 페이스 $it"
        }
        elapsedSpeech(elapsedMs)?.let {
            parts += "시간 $it"
        }
        ghostGapSpeech(ghostGapMs)?.let {
            parts += it
        }
        return parts.joinToString(", ")
    }

    fun ghostGapSpeech(gapMs: Long?): String? {
        if (gapMs == null || gapMs == 0L) return null
        val gap = gapSpeech(gapMs)
        return if (gapMs > 0L) {
            "고스트보다 $gap 앞서요"
        } else {
            "고스트보다 $gap 뒤처져요"
        }
    }

    fun ghostCompletion(frame: WearGhostFrame?): String {
        val gapMs = frame?.timeGapMs ?: 0L
        if (gapMs == 0L || frame?.status == WearGhostStatus.Level) {
            return "고스트 코스 완료, 거의 같아요"
        }
        val gap = gapSpeech(gapMs)
        return if (gapMs > 0L) {
            "고스트 코스 완료, $gap 빨랐어요"
        } else {
            "고스트 코스 완료, $gap 늦었어요"
        }
    }

    fun ghostStatus(frame: WearGhostFrame): String? {
        return when (frame.status) {
            WearGhostStatus.Ahead -> "앞섬 ${gapSpeech(frame.timeGapMs)}"
            WearGhostStatus.Behind -> "뒤처짐 ${gapSpeech(frame.timeGapMs)}"
            WearGhostStatus.Level -> "접전"
            WearGhostStatus.OffRoute -> "경로 이탈"
            WearGhostStatus.Unavailable -> null
        }
    }

    private fun paceSpeech(paceSecPerKm: Double?): String? {
        val pace = paceSecPerKm?.takeIf { it.isFinite() && it > 0 } ?: return null
        val totalSeconds = pace.roundToInt().coerceAtLeast(1)
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return if (seconds == 0) {
            "${minutes}분"
        } else {
            "${minutes}분 ${seconds}초"
        }
    }

    private fun elapsedSpeech(elapsedMs: Long?): String? {
        val totalSeconds = elapsedMs
            ?.takeIf { it > 0L }
            ?.let { (it / 1000L).coerceAtLeast(1L) }
            ?: return null
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        val parts = mutableListOf<String>()
        if (hours > 0) parts += "${hours}시간"
        if (minutes > 0) parts += "${minutes}분"
        if (seconds > 0 || parts.isEmpty()) parts += "${seconds}초"
        return parts.joinToString(" ")
    }

    private fun gapSpeech(gapMs: Long): String {
        val totalSeconds = kotlin.math.abs(gapMs / 1000).coerceAtLeast(1L)
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return if (minutes <= 0) {
            "${seconds}초"
        } else if (seconds == 0L) {
            "${minutes}분"
        } else {
            "${minutes}분 ${seconds}초"
        }
    }
}

private fun WearGhostFrame.gapForKilometerCue(): Long? {
    if (status == WearGhostStatus.OffRoute || status == WearGhostStatus.Unavailable) {
        return null
    }
    return timeGapMs.takeIf { it != 0L }
}

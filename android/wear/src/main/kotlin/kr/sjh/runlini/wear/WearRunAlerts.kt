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
) {
    private var lastAlertedKm: Int = 0
    private var lastIntervalStepLabel: String? = null
    private val ghostEventEngine = WearGhostRaceEventEngine()

    fun reset() {
        lastAlertedKm = 0
        lastIntervalStepLabel = null
        ghostEventEngine.reset()
    }

    fun onDistanceChanged(
        distanceM: Double,
        averagePaceSecPerKm: Double?,
        settings: WearRunSettings,
        elapsedMs: Long? = null,
        isGhostRun: Boolean = false,
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
                ),
                settings.voiceCueVolume,
            )
        }
    }

    fun onGhostFrame(
        frame: WearGhostFrame?,
        settings: WearRunSettings,
        isGhostRun: Boolean,
        nowMs: Long = System.currentTimeMillis(),
    ) {
        if (!isGhostRun) return
        val events = ghostEventEngine.eventsFor(
            frame = frame,
            isRunning = true,
            nowMs = nowMs,
        )
        if (events.isEmpty()) return
        if (settings.vibrationEnabled) {
            events.forEach { _ -> haptics.tick() }
        }
        if (settings.voiceCueEnabled && settings.ghostVoiceCueEnabled) {
            events.mapNotNull { WearRunVoiceCueFormatter.ghostEvent(it) }
                .forEach { speech.speak(it, settings.voiceCueVolume) }
        }
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
        if (isGhostRun && settings.voiceCueEnabled && settings.ghostVoiceCueEnabled) {
            speech.speak(
                WearRunVoiceCueFormatter.ghostCompleted(frame),
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
    fun kilometerSummary(
        kilometer: Int,
        averagePaceSecPerKm: Double?,
        elapsedMs: Long? = null,
    ): String {
        val parts = mutableListOf("${kilometer}킬로미터")
        paceSpeech(averagePaceSecPerKm)?.let {
            parts += "평균 페이스 $it"
        }
        elapsedSpeech(elapsedMs)?.let {
            parts += "시간 $it"
        }
        return parts.joinToString(", ")
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

    fun ghostEvent(event: WearGhostRaceEvent): String? {
        val frame = event.frame
        val gap = ghostGapPhrase(frame)
        return when (event.type) {
            WearGhostRaceEventType.OffRoute -> "경로를 벗어났어요"
            WearGhostRaceEventType.BackOnRoute -> "경로로 돌아왔어요"
            WearGhostRaceEventType.Overtake -> gap?.let {
                "고스트를 추월했어요, $it"
            } ?: "고스트를 추월했어요"
            WearGhostRaceEventType.LostLead -> gap?.let {
                "고스트에게 역전당했어요, $it"
            } ?: "고스트에게 역전당했어요"
            WearGhostRaceEventType.Last500m -> "마지막 500미터"
            WearGhostRaceEventType.Last200m -> "마지막 200미터"
            WearGhostRaceEventType.Completed -> ghostCompleted(frame)
        }
    }

    fun ghostCompleted(frame: WearGhostFrame?): String {
        val gap = frame?.let(::ghostGapPhrase)
        return gap?.let { "고스트 코스 완료, $it" } ?: "고스트 코스 완료"
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

    private fun ghostGapPhrase(frame: WearGhostFrame): String? {
        return when (frame.status) {
            WearGhostStatus.Ahead -> "${gapSpeech(frame.timeGapMs)} 앞서요"
            WearGhostStatus.Behind -> "${gapSpeech(frame.timeGapMs)} 뒤처져요"
            WearGhostStatus.Level,
            WearGhostStatus.OffRoute,
            WearGhostStatus.Unavailable -> null
        }
    }
}

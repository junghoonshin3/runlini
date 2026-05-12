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
    private var speechCycleActive: Boolean = false
    private var speechEmittedInCycle: Boolean = false
    private val recordRaceEventEngine = WearRecordRaceEventEngine()

    fun beginAlertCycle() {
        speechCycleActive = true
        speechEmittedInCycle = false
    }

    fun reset() {
        lastAlertedKm = 0
        lastIntervalStepLabel = null
        speechCycleActive = false
        speechEmittedInCycle = false
        recordRaceEventEngine.reset()
    }

    fun onDistanceChanged(
        distanceM: Double,
        averagePaceSecPerKm: Double?,
        settings: WearRunSettings,
        elapsedMs: Long? = null,
        isRecordRaceRun: Boolean = false,
        recordRaceFrame: WearRecordRaceFrame? = null,
    ): Boolean {
        val currentKm = floor(distanceM / 1000.0).toInt()
        if (currentKm <= 0 || currentKm <= lastAlertedKm) return false
        lastAlertedKm = currentKm
        if (settings.vibrationEnabled && settings.kmAlertEnabled) {
            haptics.tick()
        }
        if (settings.voiceCueEnabled && settings.kmAlertEnabled) {
            return speak(
                text = WearRunVoiceCueFormatter.kilometerSummary(
                    kilometer = currentKm,
                    averagePaceSecPerKm = averagePaceSecPerKm,
                    elapsedMs = elapsedMs,
                    recordRaceGapMs = if (isRecordRaceRun && settings.recordRaceVoiceCueEnabled) {
                        recordRaceGapMsForSpeech(recordRaceFrame)
                    } else {
                        null
                    },
                ),
                volume = settings.voiceCueVolume,
                useCycleBudget = isRecordRaceRun,
            )
        }
        return false
    }

    fun onRecordRaceFrame(
        frame: WearRecordRaceFrame?,
        settings: WearRunSettings,
        isRecordRaceRun: Boolean,
        nowMs: Long = System.currentTimeMillis(),
    ): Boolean {
        if (!isRecordRaceRun) return false
        val events = recordRaceEventEngine.eventsFor(
            frame = frame,
            isRunning = true,
            nowMs = nowMs,
        )
        if (events.isEmpty()) return false
        if (settings.vibrationEnabled) {
            events.forEach { _ -> haptics.tick() }
        }
        if (settings.voiceCueEnabled && settings.recordRaceVoiceCueEnabled) {
            val event = events.minByOrNull { recordRaceEventPriority(it.type) } ?: return false
            val text = WearRunVoiceCueFormatter.recordRaceEvent(event) ?: return false
            return speak(text, settings.voiceCueVolume)
        }
        return false
    }

    fun onIntervalFrame(
        frame: WearIntervalFrame?,
        settings: WearRunSettings,
        isRecordRaceRun: Boolean = false,
    ): Boolean {
        val label = WearIntervalFormatters.stepLabel(frame?.step)
        if (frame == null || label == lastIntervalStepLabel) return false
        lastIntervalStepLabel = label
        if (settings.vibrationEnabled) {
            haptics.tick()
        }
        if (!isRecordRaceRun && settings.voiceCueEnabled) {
            speech.speak(label, settings.voiceCueVolume)
            return true
        }
        return false
    }

    fun onRecordRaceCompleted(
        settings: WearRunSettings,
        isRecordRaceRun: Boolean,
        frame: WearRecordRaceFrame? = null,
    ): Boolean {
        if (isRecordRaceRun && settings.vibrationEnabled) {
            haptics.tick()
        }
        if (isRecordRaceRun && settings.voiceCueEnabled && settings.recordRaceVoiceCueEnabled) {
            return speak(
                WearRunVoiceCueFormatter.recordRaceCompleted(frame),
                settings.voiceCueVolume,
            )
        }
        return false
    }

    private fun recordRaceGapMsForSpeech(frame: WearRecordRaceFrame?): Long? {
        if (frame == null || !frame.startConfirmed || frame.status == WearRecordRaceStatus.OffRoute) {
            return null
        }
        return when (frame.status) {
            WearRecordRaceStatus.Ahead,
            WearRecordRaceStatus.Behind -> frame.timeGapMs
            WearRecordRaceStatus.Level,
            WearRecordRaceStatus.OffRoute,
            WearRecordRaceStatus.Unavailable -> null
        }
    }

    private fun speak(
        text: String,
        volume: Float,
        useCycleBudget: Boolean = true,
    ): Boolean {
        if (useCycleBudget && speechCycleActive && speechEmittedInCycle) {
            return false
        }
        speech.speak(text, volume)
        if (useCycleBudget && speechCycleActive) {
            speechEmittedInCycle = true
        }
        return true
    }

    private fun recordRaceEventPriority(type: WearRecordRaceEventType): Int {
        return when (type) {
            WearRecordRaceEventType.Completed -> 0
            WearRecordRaceEventType.OffRoute,
            WearRecordRaceEventType.BackOnRoute -> 10
            WearRecordRaceEventType.Overtake,
            WearRecordRaceEventType.LostLead -> 20
            WearRecordRaceEventType.Last200m -> 30
            WearRecordRaceEventType.Last500m -> 31
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
        recordRaceGapMs: Long? = null,
    ): String {
        val parts = mutableListOf("${kilometer}킬로미터")
        paceSpeech(averagePaceSecPerKm)?.let {
            parts += "평균 페이스 $it"
        }
        elapsedSpeech(elapsedMs)?.let {
            parts += "시간 $it"
        }
        recordRaceGapPhrase(recordRaceGapMs)?.let {
            parts += it
        }
        return parts.joinToString(". ")
    }

    fun recordRaceStatus(frame: WearRecordRaceFrame): String? {
        return when (frame.status) {
            WearRecordRaceStatus.Ahead -> "앞섬 ${gapSpeech(frame.timeGapMs)}"
            WearRecordRaceStatus.Behind -> "뒤처짐 ${gapSpeech(frame.timeGapMs)}"
            WearRecordRaceStatus.Level -> "접전"
            WearRecordRaceStatus.OffRoute -> "경로 이탈"
            WearRecordRaceStatus.Unavailable -> null
        }
    }

    fun recordRaceEvent(event: WearRecordRaceEvent): String? {
        val frame = event.frame
        val gap = recordRaceGapPhrase(frame)
        return when (event.type) {
            WearRecordRaceEventType.OffRoute -> "경로를 벗어났어요"
            WearRecordRaceEventType.BackOnRoute -> "경로로 돌아왔어요"
            WearRecordRaceEventType.Overtake -> gap?.let {
                "기록 레이스를 추월했어요. 지금은 $it"
            } ?: "기록 레이스를 추월했어요"
            WearRecordRaceEventType.LostLead -> gap?.let {
                "기록 레이스에게 역전당했어요. 지금은 $it"
            } ?: "기록 레이스에게 역전당했어요"
            WearRecordRaceEventType.Last500m -> "마지막 500미터"
            WearRecordRaceEventType.Last200m -> "마지막 200미터"
            WearRecordRaceEventType.Completed -> recordRaceCompleted(frame)
        }
    }

    fun recordRaceCompleted(frame: WearRecordRaceFrame?): String {
        val targetFrame = frame ?: return "기록 레이스 코스 완료"
        if (targetFrame.timeGapMs == 0L || targetFrame.status == WearRecordRaceStatus.Level) {
            return "기록 레이스 코스 완료. 거의 같아요"
        }
        return when (targetFrame.status) {
            WearRecordRaceStatus.Ahead -> {
                "기록 레이스 코스 완료. 기록 레이스보다 ${gapSpeech(targetFrame.timeGapMs)} 빨랐어요"
            }
            WearRecordRaceStatus.Behind -> {
                "기록 레이스 코스 완료. 기록 레이스보다 ${gapSpeech(targetFrame.timeGapMs)} 늦었어요"
            }
            WearRecordRaceStatus.Level -> "기록 레이스 코스 완료. 거의 같아요"
            WearRecordRaceStatus.OffRoute,
            WearRecordRaceStatus.Unavailable -> "기록 레이스 코스 완료"
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

    private fun recordRaceGapPhrase(frame: WearRecordRaceFrame): String? {
        return recordRaceGapPhrase(
            when (frame.status) {
                WearRecordRaceStatus.Ahead,
                WearRecordRaceStatus.Behind -> frame.timeGapMs
                WearRecordRaceStatus.Level,
                WearRecordRaceStatus.OffRoute,
                WearRecordRaceStatus.Unavailable -> null
            },
        )
    }

    private fun recordRaceGapPhrase(gapMs: Long?): String? {
        if (gapMs == null || gapMs == 0L) return null
        val gap = gapSpeech(gapMs)
        return if (gapMs > 0L) {
            "기록 레이스보다 $gap 앞서고 있어요"
        } else {
            "기록 레이스보다 $gap 뒤처지고 있어요"
        }
    }
}

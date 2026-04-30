package kr.sjh.runlini.wear

import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import kotlin.math.floor
import kotlin.math.roundToInt

private const val GhostVoiceCueDebounceMs = 30_000L

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
    private val nowMs: () -> Long = { SystemClock.elapsedRealtime() },
) {
    private var lastAlertedKm: Int = 0
    private var lastSpokenGhostStatus: WearGhostStatus? = null
    private var lastGhostSpokenAtMs: Long? = null

    fun reset() {
        lastAlertedKm = 0
        lastSpokenGhostStatus = null
        lastGhostSpokenAtMs = null
    }

    fun onDistanceChanged(
        distanceM: Double,
        averagePaceSecPerKm: Double?,
        settings: WearRunSettings,
    ) {
        val currentKm = floor(distanceM / 1000.0).toInt()
        if (currentKm <= 0 || currentKm <= lastAlertedKm) return
        lastAlertedKm = currentKm
        if (settings.vibrationEnabled && settings.kmAlertEnabled) {
            haptics.tick()
        }
        if (settings.voiceCueEnabled) {
            speech.speak(
                WearRunVoiceCueFormatter.kilometerSummary(
                    kilometer = currentKm,
                    averagePaceSecPerKm = averagePaceSecPerKm,
                ),
            )
        }
    }

    fun onGhostFrame(
        frame: WearGhostFrame?,
        settings: WearRunSettings,
        isGhostRun: Boolean,
    ) {
        if (!isGhostRun || !settings.ghostVoiceCueEnabled) return
        val status = frame?.status ?: return
        if (status == WearGhostStatus.Unavailable || status == lastSpokenGhostStatus) return
        val now = nowMs()
        val lastSpokenAt = lastGhostSpokenAtMs
        if (lastSpokenAt != null && now - lastSpokenAt < GhostVoiceCueDebounceMs) return
        val cue = WearRunVoiceCueFormatter.ghostStatus(frame) ?: return
        speech.speak(cue)
        lastSpokenGhostStatus = status
        lastGhostSpokenAtMs = now
    }

    fun shutdown() {
        speech.shutdown()
    }
}

internal object WearRunVoiceCueFormatter {
    fun kilometerSummary(
        kilometer: Int,
        averagePaceSecPerKm: Double?,
    ): String {
        val pace = paceSpeech(averagePaceSecPerKm)
        return if (pace == null) {
            "${kilometer}킬로미터"
        } else {
            "${kilometer}킬로미터, 평균 페이스 $pace"
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

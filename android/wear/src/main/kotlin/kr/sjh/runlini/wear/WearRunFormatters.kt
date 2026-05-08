package kr.sjh.runlini.wear

import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.roundToInt

internal object WearRunFormatters {
    fun elapsed(elapsedMs: Long): String {
        val totalSeconds = (elapsedMs / 1000).coerceAtLeast(0)
        val hours = totalSeconds / 3600
        val minutes = (totalSeconds % 3600) / 60
        val seconds = totalSeconds % 60
        return if (hours > 0) {
            "%d:%02d:%02d".format(hours, minutes, seconds)
        } else {
            "%02d:%02d".format(minutes, seconds)
        }
    }

    fun distance(distanceM: Double): String {
        return "%.2f km".format(distanceM.coerceAtLeast(0.0) / 1000.0)
    }

    fun distanceHero(distanceM: Double): WearDistanceHeroText {
        return WearDistanceHeroText(
            value = "%.2f".format(distanceM.coerceAtLeast(0.0) / 1000.0),
            unit = "km",
        )
    }

    fun pace(paceSecPerKm: Double?): String {
        val pace = paceSecPerKm?.takeIf { it.isFinite() && it > 0 } ?: return "--"
        val minutes = floor(pace / 60.0).toInt()
        val seconds = (pace.roundToInt() % 60).coerceIn(0, 59)
        return "%d:%02d/km".format(minutes, seconds)
    }

    fun speed(speedMps: Double?): String {
        val speed = speedMps?.takeIf { it.isFinite() && it > 0 } ?: return "--"
        return "%.1f km/h".format(speed * 3.6)
    }

    fun heartRate(heartRateBpm: Int?): String {
        return heartRateBpm?.let { "$it bpm" } ?: "--"
    }

    fun calories(caloriesKcal: Double?): String {
        return caloriesKcal?.roundToInt()?.let { "$it kcal" } ?: "--"
    }

    fun cadence(cadenceSpm: Double?): String {
        val cadence = cadenceSpm?.takeIf { it.isFinite() && it > 0 } ?: return "--"
        return "${cadence.roundToInt()} spm"
    }

    fun ghostStatusLabel(status: WearGhostStatus?): String {
        return when (status) {
            WearGhostStatus.Ahead -> "앞서는 중"
            WearGhostStatus.Behind -> "뒤처지는 중"
            WearGhostStatus.Level -> "접전"
            WearGhostStatus.OffRoute -> "경로 이탈"
            WearGhostStatus.Unavailable, null -> "고스트 준비 중"
        }
    }

    fun ghostGap(frame: WearGhostFrame?): String {
        val gapMs = frame?.timeGapMs ?: return "--"
        val sign = if (gapMs >= 0) "+" else "-"
        val totalSeconds = (abs(gapMs) / 1000).coerceAtLeast(0L)
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return "$sign$minutes:%02d".format(seconds)
    }

    fun ghostResult(frame: WearGhostFrame?): String {
        return "${ghostStatusLabel(frame?.status)} ${ghostGap(frame)}"
    }

    fun ghostProgress(frame: WearGhostFrame?): String {
        val progress = frame?.routeProgress
            ?.takeIf { it.isFinite() }
            ?: return "--"
        return "${(progress.coerceIn(0.0, 1.0) * 100.0).roundToInt()}%"
    }

    fun ghostRemaining(frame: WearGhostFrame?): String {
        val remaining = frame?.distanceToFinishM
            ?.takeIf { it.isFinite() && it >= 0.0 }
            ?: return "--"
        return if (remaining >= 1000.0) {
            "%.1f km".format(remaining / 1000.0)
        } else {
            "${remaining.roundToInt()} m"
        }
    }
}

internal data class WearDistanceHeroText(
    val value: String,
    val unit: String,
)

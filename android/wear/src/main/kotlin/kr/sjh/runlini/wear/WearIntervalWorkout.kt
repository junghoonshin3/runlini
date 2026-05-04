package kr.sjh.runlini.wear

import org.json.JSONObject
import java.util.Locale
import kotlin.math.max
import kotlin.math.roundToInt

enum class WearIntervalTargetType { Time, Distance, Open, Skip }
enum class WearIntervalStepKind { Warmup, Work, Recovery, Cooldown, Finished }

data class WearIntervalTarget(
    val type: WearIntervalTargetType,
    val durationMs: Long? = null,
    val distanceM: Double? = null,
) {
    companion object {
        val DefaultWarmup = WearIntervalTarget(WearIntervalTargetType.Time, 300_000L)
        val DefaultWork = WearIntervalTarget(WearIntervalTargetType.Time, 60_000L)
        val DefaultRecovery = WearIntervalTarget(WearIntervalTargetType.Time, 60_000L)
        val DefaultCooldown = WearIntervalTarget(WearIntervalTargetType.Time, 300_000L)
    }
}

data class WearIntervalWorkout(
    val enabled: Boolean = false,
    val warmup: WearIntervalTarget = WearIntervalTarget.DefaultWarmup,
    val work: WearIntervalTarget = WearIntervalTarget.DefaultWork,
    val recovery: WearIntervalTarget = WearIntervalTarget.DefaultRecovery,
    val repeatCount: Int = 8,
    val cooldown: WearIntervalTarget = WearIntervalTarget.DefaultCooldown,
)

data class WearIntervalStep(
    val kind: WearIntervalStepKind,
    val target: WearIntervalTarget,
    val repeatIndex: Int?,
    val repeatCount: Int,
)

data class WearIntervalFrame(
    val step: WearIntervalStep,
    val nextStep: WearIntervalStep?,
    val remainingMs: Long?,
    val remainingM: Double?,
    val progress: Double,
)

data class WearIntervalHeroText(
    val label: String,
    val value: String,
)

object WearIntervalWorkoutJsonMapper {
    fun toJson(workout: WearIntervalWorkout): String {
        return JSONObject()
            .put("enabled", workout.enabled)
            .put("warmup", targetToJson(workout.warmup))
            .put("work", targetToJson(workout.work))
            .put("recovery", targetToJson(workout.recovery))
            .put("repeatCount", workout.repeatCount)
            .put("cooldown", targetToJson(workout.cooldown))
            .toString()
    }

    fun fromJson(json: String): WearIntervalWorkout {
        val objectJson = JSONObject(json)
        return WearIntervalWorkout(
            enabled = objectJson.optBoolean("enabled", false),
            warmup = targetFromJson(
                objectJson.optJSONObject("warmup"),
                WearIntervalTarget.DefaultWarmup,
            ),
            work = targetFromJson(
                objectJson.optJSONObject("work"),
                WearIntervalTarget.DefaultWork,
            ),
            recovery = targetFromJson(
                objectJson.optJSONObject("recovery"),
                WearIntervalTarget.DefaultRecovery,
            ),
            repeatCount = objectJson.optInt("repeatCount", 8).coerceIn(1, 99),
            cooldown = targetFromJson(
                objectJson.optJSONObject("cooldown"),
                WearIntervalTarget.DefaultCooldown,
            ),
        )
    }

    private fun targetToJson(target: WearIntervalTarget): JSONObject {
        return JSONObject()
            .put("type", target.type.jsonName())
            .put("durationMs", target.durationMs)
            .put("distanceM", target.distanceM)
    }

    private fun targetFromJson(
        json: JSONObject?,
        fallback: WearIntervalTarget,
    ): WearIntervalTarget {
        if (json == null) return fallback
        val type = when (json.optString("type")) {
            "time" -> WearIntervalTargetType.Time
            "distance" -> WearIntervalTargetType.Distance
            "open" -> WearIntervalTargetType.Open
            "skip" -> WearIntervalTargetType.Skip
            else -> fallback.type
        }
        return WearIntervalTarget(
            type = type,
            durationMs = json.optLong("durationMs").takeIf { it > 0 },
            distanceM = json.optDouble("distanceM").takeIf { it.isFinite() && it > 0 },
        )
    }

    private fun WearIntervalTargetType.jsonName(): String {
        return when (this) {
            WearIntervalTargetType.Time -> "time"
            WearIntervalTargetType.Distance -> "distance"
            WearIntervalTargetType.Open -> "open"
            WearIntervalTargetType.Skip -> "skip"
        }
    }
}

class WearIntervalWorkoutCalculator {
    fun calculate(
        workout: WearIntervalWorkout,
        elapsedMs: Long,
        distanceM: Double,
    ): WearIntervalFrame? {
        if (!workout.enabled) return null
        val steps = buildSteps(workout)
        var stepStartMs = 0L
        var stepStartDistanceM = 0.0
        for (index in steps.indices) {
            val step = steps[index]
            val progress = progressFor(
                step.target,
                elapsedMs - stepStartMs,
                distanceM - stepStartDistanceM,
            )
            if (!progress.isComplete) {
                return WearIntervalFrame(
                    step = step,
                    nextStep = steps.getOrNull(index + 1),
                    remainingMs = progress.remainingMs,
                    remainingM = progress.remainingM,
                    progress = progress.ratio,
                )
            }
            stepStartMs += progress.targetDurationMs ?: 0L
            stepStartDistanceM += progress.targetDistanceM ?: 0.0
        }
        return WearIntervalFrame(
            step = WearIntervalStep(
                WearIntervalStepKind.Finished,
                WearIntervalTarget(WearIntervalTargetType.Skip),
                null,
                workout.repeatCount,
            ),
            nextStep = null,
            remainingMs = 0L,
            remainingM = null,
            progress = 1.0,
        )
    }

    fun buildSteps(workout: WearIntervalWorkout): List<WearIntervalStep> {
        return buildList {
            addStep(WearIntervalStepKind.Warmup, workout.warmup, null, workout)
            for (repeat in 1..workout.repeatCount) {
                addStep(WearIntervalStepKind.Work, workout.work, repeat, workout)
                addStep(WearIntervalStepKind.Recovery, workout.recovery, repeat, workout)
            }
            addStep(WearIntervalStepKind.Cooldown, workout.cooldown, null, workout)
        }
    }

    private fun MutableList<WearIntervalStep>.addStep(
        kind: WearIntervalStepKind,
        target: WearIntervalTarget,
        repeatIndex: Int?,
        workout: WearIntervalWorkout,
    ) {
        if (target.type == WearIntervalTargetType.Skip) return
        add(WearIntervalStep(kind, target, repeatIndex, workout.repeatCount))
    }

    private fun progressFor(
        target: WearIntervalTarget,
        elapsedMs: Long,
        distanceM: Double,
    ): IntervalProgress {
        return when (target.type) {
            WearIntervalTargetType.Time -> {
                val targetMs = max(1L, target.durationMs ?: 1L)
                IntervalProgress(
                    isComplete = elapsedMs >= targetMs,
                    remainingMs = max(0L, targetMs - elapsedMs),
                    ratio = (elapsedMs.toDouble() / targetMs).coerceIn(0.0, 1.0),
                    targetDurationMs = targetMs,
                )
            }
            WearIntervalTargetType.Distance -> {
                val targetM = max(1.0, target.distanceM ?: 1.0)
                IntervalProgress(
                    isComplete = distanceM >= targetM,
                    remainingM = max(0.0, targetM - distanceM),
                    ratio = (distanceM / targetM).coerceIn(0.0, 1.0),
                    targetDistanceM = targetM,
                )
            }
            WearIntervalTargetType.Open -> IntervalProgress(false, 0.0)
            WearIntervalTargetType.Skip -> IntervalProgress(true, 1.0)
        }
    }
}

private data class IntervalProgress(
    val isComplete: Boolean,
    val ratio: Double,
    val remainingMs: Long? = null,
    val remainingM: Double? = null,
    val targetDurationMs: Long? = null,
    val targetDistanceM: Double? = null,
)

object WearIntervalFormatters {
    fun target(target: WearIntervalTarget): String {
        return when (target.type) {
            WearIntervalTargetType.Time -> {
                val totalSeconds = ((target.durationMs ?: 0L) / 1000L).coerceAtLeast(0L)
                val minutes = totalSeconds / 60L
                val seconds = totalSeconds % 60L
                when {
                    minutes <= 0L -> "${seconds}초"
                    seconds == 0L -> "${minutes}분"
                    else -> "%d:%02d".format(minutes, seconds)
                }
            }
            WearIntervalTargetType.Distance -> {
                val meters = target.distanceM ?: 0.0
                if (meters >= 1000.0) {
                    "${(meters / 1000.0).roundToInt()}km"
                } else {
                    "${meters.roundToInt()}m"
                }
            }
            WearIntervalTargetType.Open -> "오픈"
            WearIntervalTargetType.Skip -> "끄기"
        }
    }

    fun stepLabel(step: WearIntervalStep?): String {
        if (step == null) return "끝"
        val base = when (step.kind) {
            WearIntervalStepKind.Warmup -> "워밍업"
            WearIntervalStepKind.Work -> "질주"
            WearIntervalStepKind.Recovery -> "휴식"
            WearIntervalStepKind.Cooldown -> "쿨다운"
            WearIntervalStepKind.Finished -> "완료"
        }
        return step.repeatIndex?.let { "$base $it/${step.repeatCount}" } ?: base
    }

    fun remaining(frame: WearIntervalFrame?): String {
        frame ?: return "--"
        frame.remainingM?.let { return "남은 ${it.roundToInt()}m" }
        val ms = frame.remainingMs ?: return "직접 넘기기"
        val totalSeconds = (ms / 1000).coerceAtLeast(0)
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return if (minutes > 0) {
            "남은 %d:%02d".format(minutes, seconds)
        } else {
            "남은 ${seconds}초"
        }
    }

    fun heroRemaining(frame: WearIntervalFrame?): WearIntervalHeroText {
        frame ?: return WearIntervalHeroText("인터벌", "--")
        frame.remainingM?.let {
            return WearIntervalHeroText("남은 거리", heroDistance(it))
        }
        val ms = frame.remainingMs ?: return WearIntervalHeroText("인터벌", "직접")
        return WearIntervalHeroText("남은 시간", heroDuration(ms))
    }

    private fun heroDuration(ms: Long): String {
        val totalSeconds = (ms / 1000).coerceAtLeast(0)
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return if (minutes > 0) {
            "%d:%02d".format(minutes, seconds)
        } else {
            "${seconds}초"
        }
    }

    private fun heroDistance(meters: Double): String {
        val safeMeters = meters.coerceAtLeast(0.0)
        return if (safeMeters >= 1000.0) {
            val km = safeMeters / 1000.0
            if (km >= 10.0) {
                "${km.roundToInt()}km"
            } else {
                String.format(Locale.US, "%.1fkm", km)
            }
        } else {
            "${safeMeters.roundToInt()}m"
        }
    }
}

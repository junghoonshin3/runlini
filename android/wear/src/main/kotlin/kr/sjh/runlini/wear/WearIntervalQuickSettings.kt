package kr.sjh.runlini.wear

object WearIntervalQuickSettings {
    private const val TimeStepMs = 10_000L
    private const val MinTimeMs = 10_000L
    private const val MaxTimeMs = 30 * 60 * 1000L
    private const val DistanceStepM = 50.0
    private const val MinDistanceM = 50.0
    private const val MaxDistanceM = 10_000.0

    private val OneMinute = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 60_000L)
    private val FourHundredMeters = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 400.0)
    private val TwoHundredMeters = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 200.0)

    fun normalize(workout: WearIntervalWorkout): WearIntervalWorkout {
        return workout.copy(
            work = normalizeTarget(workout.work, isWork = true),
            recovery = normalizeTarget(workout.recovery, isWork = false),
            repeatCount = workout.repeatCount.coerceIn(1, 30),
        )
    }

    fun toggleTargetType(target: WearIntervalTarget, isWork: Boolean): WearIntervalTarget {
        return if (target.type == WearIntervalTargetType.Distance) {
            OneMinute
        } else if (isWork) {
            FourHundredMeters
        } else {
            TwoHundredMeters
        }
    }

    fun stepTarget(
        target: WearIntervalTarget,
        isWork: Boolean,
        delta: Int,
    ): WearIntervalTarget {
        val normalized = normalizeTarget(target, isWork)
        return when (normalized.type) {
            WearIntervalTargetType.Distance -> {
                val next = ((normalized.distanceM ?: MinDistanceM) + (delta * DistanceStepM))
                    .coerceIn(MinDistanceM, MaxDistanceM)
                WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = next)
            }
            else -> {
                val next = ((normalized.durationMs ?: MinTimeMs) + (delta * TimeStepMs))
                    .coerceIn(MinTimeMs, MaxTimeMs)
                WearIntervalTarget(WearIntervalTargetType.Time, durationMs = next)
            }
        }
    }

    fun stepRepeat(repeatCount: Int, delta: Int): Int {
        return (repeatCount + delta).coerceIn(1, 30)
    }

    private fun normalizeTarget(
        target: WearIntervalTarget,
        isWork: Boolean,
    ): WearIntervalTarget {
        return when (target.type) {
            WearIntervalTargetType.Distance -> {
                val fallback = if (isWork) FourHundredMeters else TwoHundredMeters
                WearIntervalTarget(
                    WearIntervalTargetType.Distance,
                    distanceM = (target.distanceM ?: fallback.distanceM ?: MinDistanceM)
                        .coerceIn(MinDistanceM, MaxDistanceM),
                )
            }
            else -> WearIntervalTarget(
                WearIntervalTargetType.Time,
                durationMs = (target.durationMs ?: OneMinute.durationMs ?: MinTimeMs)
                    .coerceIn(MinTimeMs, MaxTimeMs),
            )
        }
    }
}

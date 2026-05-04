package kr.sjh.runlini.wear

import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.math.sqrt

enum class WearAutoPauseDecision { None, Pause, Resume }

class WearAutoPauseDetector(
    private val stationaryWindowMs: Long = 8_000L,
    private val stationaryClusterRadiusM: Double = 15.0,
    private val stationarySpeedMps: Double = 0.8,
    private val resumeSpeedMps: Double = 1.2,
    private val resumeConfirmationCount: Int = 2,
    private val motionWindowMs: Long = 4_000L,
    private val minCadenceSpm: Double = 40.0,
) {
    private val recentPoints = ArrayDeque<WearRunPoint>()
    private val recentCadence = ArrayDeque<WearCadenceEvidence>()
    private var cadenceSourceKnown = false

    fun reset() {
        recentPoints.clear()
        recentCadence.clear()
        cadenceSourceKnown = false
    }

    fun onSample(state: WearRunState, sample: WearMetricSample): WearAutoPauseDecision {
        sample.points.forEach(::addPoint)
        addCadence(sample)
        if (!state.settings.autoPauseEnabled || state.points.isEmpty()) {
            return WearAutoPauseDecision.None
        }
        val latestMs = sample.points.lastOrNull()?.timestampRelMs ?: sample.activeDurationMs ?: state.elapsedMs
        return when {
            state.phase == WearRunPhase.Running &&
                hasStationaryWindow() &&
                shouldPauseForStationary(latestMs) -> {
                WearAutoPauseDecision.Pause
            }
            state.phase == WearRunPhase.Paused &&
                state.pauseReason == WearPauseReason.Auto &&
                hasMovementConfirmation(state.points.last(), latestMs) -> {
                WearAutoPauseDecision.Resume
            }
            else -> WearAutoPauseDecision.None
        }
    }

    fun filterStationaryDrift(state: WearRunState, sample: WearMetricSample): WearMetricSample {
        if (sample.points.isEmpty() || state.points.isEmpty()) return sample
        val latest = sample.points.last()
        val anchor = state.points.last()
        val distance = distanceMeters(anchor, latest)
        val radius = max(
            stationaryClusterRadiusM,
            max(anchor.horizontalAccuracyM ?: 0.0, latest.horizontalAccuracyM ?: 0.0),
        )
        val stationarySpeed = latest.speedMps == null || latest.speedMps <= stationarySpeedMps
        if (stationarySpeed && distance <= radius) {
            return sample.copy(distanceM = null, paceSecPerKm = null, speedMps = null, points = emptyList())
        }
        return sample
    }

    private fun addPoint(point: WearRunPoint) {
        recentPoints.addLast(point)
        val latestMs = point.timestampRelMs
        while (recentPoints.isNotEmpty() &&
            latestMs - recentPoints.first().timestampRelMs > stationaryWindowMs + 2_000L
        ) {
            recentPoints.removeFirst()
        }
    }

    private fun addCadence(sample: WearMetricSample) {
        val cadence = sample.cadenceSpm ?: return
        cadenceSourceKnown = true
        val timestampMs = sample.points.lastOrNull()?.timestampRelMs ?: sample.activeDurationMs ?: return
        recentCadence.addLast(WearCadenceEvidence(timestampMs, cadence))
        while (recentCadence.isNotEmpty() &&
            timestampMs - recentCadence.first().timestampMs > stationaryWindowMs + 5_000L
        ) {
            recentCadence.removeFirst()
        }
    }

    private fun hasStationaryWindow(): Boolean {
        if (recentPoints.size < 2) return false
        val latest = recentPoints.last()
        val first = recentPoints.first()
        if (latest.timestampRelMs - first.timestampRelMs < stationaryWindowMs) return false
        return recentPoints.all { point ->
            val radius = max(
                stationaryClusterRadiusM,
                max(first.horizontalAccuracyM ?: 0.0, point.horizontalAccuracyM ?: 0.0),
            )
            val stationarySpeed = point.speedMps == null || point.speedMps <= stationarySpeedMps
            stationarySpeed && distanceMeters(first, point) <= radius
        }
    }

    private fun hasMovementConfirmation(anchor: WearRunPoint, timestampMs: Long): Boolean {
        if (recentPoints.size < resumeConfirmationCount) return false
        return hasMotionEvidence(timestampMs) && recentPoints.takeLast(resumeConfirmationCount).all { point ->
            val speedMoving = point.speedMps != null && point.speedMps >= resumeSpeedMps
            val distanceMoving = distanceMeters(anchor, point) > stationaryClusterRadiusM
            speedMoving || distanceMoving
        }
    }

    private fun hasMotionEvidence(timestampMs: Long): Boolean {
        if (!cadenceSourceKnown) return true
        return recentCadence.any { evidence ->
            timestampMs - evidence.timestampMs in 0..motionWindowMs &&
                evidence.cadenceSpm >= minCadenceSpm
        }
    }

    private fun shouldPauseForStationary(timestampMs: Long): Boolean {
        if (!cadenceSourceKnown) return true
        return !hasMotionEvidence(timestampMs)
    }

    private fun distanceMeters(left: WearRunPoint, right: WearRunPoint): Double {
        val radiusM = 6_371_000.0
        val dLat = (right.latitude - left.latitude) * PI / 180.0
        val dLon = (right.longitude - left.longitude) * PI / 180.0
        val leftLat = left.latitude * PI / 180.0
        val rightLat = right.latitude * PI / 180.0
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(leftLat) * cos(rightLat) * sin(dLon / 2) * sin(dLon / 2)
        return radiusM * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

private data class WearCadenceEvidence(
    val timestampMs: Long,
    val cadenceSpm: Double,
)

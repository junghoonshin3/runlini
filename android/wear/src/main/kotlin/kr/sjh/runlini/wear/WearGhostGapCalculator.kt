package kr.sjh.runlini.wear

import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.roundToLong
import kotlin.math.sin
import kotlin.math.sqrt

class WearGhostGapCalculator(
    private val levelThresholdMs: Long = 3_000L,
    private val levelDistanceThresholdM: Double = 3.0,
    private val offRouteThresholdM: Double = 35.0,
) {
    fun calculate(
        runnerPoint: WearRunPoint,
        ghostConfig: WearGhostConfig,
        runnerElapsedMs: Long,
    ): WearGhostFrame {
        if (!ghostConfig.canRun) {
            return WearGhostFrame(WearGhostStatus.Unavailable, 0L, 0.0)
        }

        val route = GhostRouteModel.from(ghostConfig.points)
        if (route.segments.isEmpty()) {
            val distanceGapM = distanceBetween(runnerPoint, ghostConfig.points.first())
            return WearGhostFrame(
                status = if (distanceGapM <= levelDistanceThresholdM) {
                    WearGhostStatus.Level
                } else {
                    WearGhostStatus.OffRoute
                },
                timeGapMs = 0L,
                distanceGapM = distanceGapM,
            )
        }

        val projection = route.project(runnerPoint)
        val ghostDistanceAtElapsed = route.distanceAtElapsed(runnerElapsedMs)
        val timeGapMs = projection.elapsedMs - runnerElapsedMs
        val rawDistanceGapM = projection.distanceAlongRouteM - ghostDistanceAtElapsed
        val isOffRoute = projection.distanceFromRouteM >= offRouteThresholdM
        val status = when {
            isOffRoute -> WearGhostStatus.OffRoute
            kotlin.math.abs(timeGapMs) <= levelThresholdMs -> WearGhostStatus.Level
            timeGapMs > 0L -> WearGhostStatus.Ahead
            else -> WearGhostStatus.Behind
        }
        val distanceGapM = if (kotlin.math.abs(rawDistanceGapM) <= levelDistanceThresholdM) {
            0.0
        } else {
            rawDistanceGapM
        }
        return WearGhostFrame(
            status = status,
            timeGapMs = timeGapMs,
            distanceGapM = distanceGapM,
        )
    }

    private data class GhostRouteModel(val segments: List<GhostRouteSegment>) {
        fun project(runnerPoint: WearRunPoint): RouteProjection {
            return segments
                .map { segment -> segment.project(runnerPoint) }
                .minBy { projection -> projection.distanceFromRouteM }
        }

        fun distanceAtElapsed(elapsedMs: Long): Double {
            if (elapsedMs <= segments.first().start.timestampRelMs) {
                return segments.first().startDistanceM
            }

            for (segment in segments) {
                val startMs = segment.start.timestampRelMs
                val endMs = segment.end.timestampRelMs
                if (elapsedMs > endMs) continue
                if (endMs <= startMs) return segment.startDistanceM

                val ratio = ((elapsedMs - startMs).toDouble() / (endMs - startMs))
                    .coerceIn(0.0, 1.0)
                return segment.startDistanceM +
                    ((segment.endDistanceM - segment.startDistanceM) * ratio)
            }

            return segments.last().endDistanceM
        }

        companion object {
            fun from(points: List<WearRunPoint>): GhostRouteModel {
                val segments = mutableListOf<GhostRouteSegment>()
                var distanceBeforeM = 0.0
                for (index in 0 until points.lastIndex) {
                    val start = points[index]
                    val end = points[index + 1]
                    val distanceM = distanceBetween(start, end)
                    if (distanceM <= 0.0) continue
                    val segment = GhostRouteSegment(
                        start = start,
                        end = end,
                        startDistanceM = distanceBeforeM,
                        endDistanceM = distanceBeforeM + distanceM,
                    )
                    segments.add(segment)
                    distanceBeforeM = segment.endDistanceM
                }
                return GhostRouteModel(segments)
            }
        }
    }

    private data class GhostRouteSegment(
        val start: WearRunPoint,
        val end: WearRunPoint,
        val startDistanceM: Double,
        val endDistanceM: Double,
    ) {
        fun project(runnerPoint: WearRunPoint): RouteProjection {
            val startOffset = meterOffset(
                originLatitude = runnerPoint.latitude,
                originLongitude = runnerPoint.longitude,
                latitude = start.latitude,
                longitude = start.longitude,
            )
            val endOffset = meterOffset(
                originLatitude = runnerPoint.latitude,
                originLongitude = runnerPoint.longitude,
                latitude = end.latitude,
                longitude = end.longitude,
            )
            val segmentVector = endOffset - startOffset
            val segmentLengthSquared = segmentVector.lengthSquared
            val rawRatio = if (segmentLengthSquared <= 0.0) {
                0.0
            } else {
                (MeterOffset.Zero - startOffset).dot(segmentVector) / segmentLengthSquared
            }
            val ratio = rawRatio.coerceIn(0.0, 1.0)
            val projectedOffset = startOffset + (segmentVector * ratio)
            val elapsedMs = start.timestampRelMs +
                ((end.timestampRelMs - start.timestampRelMs) * ratio).roundToLong()
            val distanceAlongRouteM =
                startDistanceM + ((endDistanceM - startDistanceM) * ratio)

            return RouteProjection(
                distanceFromRouteM = projectedOffset.distance,
                distanceAlongRouteM = distanceAlongRouteM,
                elapsedMs = elapsedMs,
            )
        }
    }

    private data class RouteProjection(
        val distanceFromRouteM: Double,
        val distanceAlongRouteM: Double,
        val elapsedMs: Long,
    )

    private data class MeterOffset(val dx: Double, val dy: Double) {
        val lengthSquared: Double
            get() = (dx * dx) + (dy * dy)
        val distance: Double
            get() = sqrt(lengthSquared)

        operator fun minus(other: MeterOffset): MeterOffset {
            return MeterOffset(dx - other.dx, dy - other.dy)
        }

        operator fun plus(other: MeterOffset): MeterOffset {
            return MeterOffset(dx + other.dx, dy + other.dy)
        }

        operator fun times(value: Double): MeterOffset {
            return MeterOffset(dx * value, dy * value)
        }

        fun dot(other: MeterOffset): Double {
            return (dx * other.dx) + (dy * other.dy)
        }

        companion object {
            val Zero = MeterOffset(0.0, 0.0)
        }
    }

    companion object {
        private const val EarthRadiusM = 6_371_000.0

        private fun distanceBetween(left: WearRunPoint, right: WearRunPoint): Double {
            val leftLat = left.latitude.toRadians()
            val rightLat = right.latitude.toRadians()
            val deltaLat = (right.latitude - left.latitude).toRadians()
            val deltaLng = (right.longitude - left.longitude).toRadians()
            val a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(leftLat) * cos(rightLat) * sin(deltaLng / 2) * sin(deltaLng / 2)
            val c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return EarthRadiusM * c
        }

        private fun meterOffset(
            originLatitude: Double,
            originLongitude: Double,
            latitude: Double,
            longitude: Double,
        ): MeterOffset {
            val latitudeScaleM = 111_320.0
            val longitudeScaleM = latitudeScaleM * cos(originLatitude * PI / 180)
            return MeterOffset(
                dx = (longitude - originLongitude) * longitudeScaleM,
                dy = (latitude - originLatitude) * latitudeScaleM,
            )
        }

        private fun Double.toRadians(): Double = this * PI / 180.0
    }
}

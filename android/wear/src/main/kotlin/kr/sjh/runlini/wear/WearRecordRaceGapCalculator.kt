package kr.sjh.runlini.wear

import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.roundToLong
import kotlin.math.sin
import kotlin.math.sqrt

class WearRecordRaceGapCalculator(
    private val levelThresholdMs: Long = 3_000L,
    private val levelDistanceThresholdM: Double = 3.0,
    private val offRouteThresholdM: Double = 35.0,
    private val startRadiusM: Double = 35.0,
    private val startRouteWindowM: Double = 100.0,
    private val requiredStartCandidates: Int = 2,
    private val projectionBehindWindowM: Double = 50.0,
    private val projectionAheadWindowM: Double = 250.0,
) {
    fun evaluateStart(
        runnerPoints: List<WearRunPoint>,
        recordRaceConfig: WearRecordRaceConfig,
        alreadyConfirmed: Boolean,
        previousCandidateCount: Int,
        lastEvaluatedPointCount: Int,
    ): WearRecordRaceStartDecision {
        if (alreadyConfirmed) {
            return WearRecordRaceStartDecision(
                isConfirmed = true,
                candidateCount = previousCandidateCount,
                lastEvaluatedPointCount = lastEvaluatedPointCount,
            )
        }
        if (runnerPoints.size < 2 || !recordRaceConfig.canRun) {
            return WearRecordRaceStartDecision(false, 0, lastEvaluatedPointCount)
        }
        if (runnerPoints.size <= lastEvaluatedPointCount) {
            return WearRecordRaceStartDecision(
                isConfirmed = false,
                candidateCount = previousCandidateCount,
                lastEvaluatedPointCount = lastEvaluatedPointCount,
            )
        }
        if (distanceBetween(runnerPoints.first(), recordRaceConfig.points.first()) > startRadiusM) {
            return WearRecordRaceStartDecision(false, 0, runnerPoints.size)
        }

        val route = RecordRaceRouteModel.from(recordRaceConfig.points)
        if (route.segments.isEmpty()) {
            return WearRecordRaceStartDecision(false, 0, runnerPoints.size)
        }
        val previousProjection = route.projectGlobal(runnerPoints[runnerPoints.lastIndex - 1])
        val currentProjection = route.projectGlobal(runnerPoints.last())
        val progressedForward =
            currentProjection.distanceAlongRouteM > previousProjection.distanceAlongRouteM + 1.0
        val onEarlyRoute =
            currentProjection.distanceAlongRouteM > 0.0 &&
                currentProjection.distanceAlongRouteM <= startRouteWindowM &&
                currentProjection.distanceFromRouteM <= offRouteThresholdM
        val nextCount = if (progressedForward && onEarlyRoute) {
            previousCandidateCount + 1
        } else {
            0
        }
        return WearRecordRaceStartDecision(
            isConfirmed = nextCount >= requiredStartCandidates,
            candidateCount = nextCount,
            lastEvaluatedPointCount = runnerPoints.size,
        )
    }

    fun calculate(
        runnerPoint: WearRunPoint,
        recordRaceConfig: WearRecordRaceConfig,
        runnerElapsedMs: Long,
        startConfirmed: Boolean = true,
        startCandidateCount: Int = 0,
        startLastEvaluatedPointCount: Int = 0,
        previousDistanceAlongRouteM: Double? = null,
    ): WearRecordRaceFrame {
        if (!recordRaceConfig.canRun) {
            return WearRecordRaceFrame(WearRecordRaceStatus.Unavailable, 0L, 0.0)
        }

        val route = RecordRaceRouteModel.from(recordRaceConfig.points)
        if (route.segments.isEmpty()) {
            val distanceGapM = distanceBetween(runnerPoint, recordRaceConfig.points.first())
            val isLevel = distanceGapM <= levelDistanceThresholdM
            return WearRecordRaceFrame(
                status = if (isLevel) {
                    WearRecordRaceStatus.Level
                } else {
                    WearRecordRaceStatus.OffRoute
                },
                timeGapMs = 0L,
                distanceGapM = distanceGapM,
                routeProgress = if (isLevel) 1.0 else 0.0,
                distanceToFinishM = if (isLevel) 0.0 else distanceGapM,
                distanceFromRouteM = distanceGapM,
                totalRouteDistanceM = 0.0,
                distanceToFinishPointM = distanceGapM,
                startConfirmed = startConfirmed,
                startCandidateCount = startCandidateCount,
                startLastEvaluatedPointCount = startLastEvaluatedPointCount,
                projectionSource = WearRecordRaceProjectionSource.Global,
            )
        }

        val projection = route.projectTracked(
            runnerPoint = runnerPoint,
            previousDistanceAlongRouteM = previousDistanceAlongRouteM,
            behindWindowM = projectionBehindWindowM,
            aheadWindowM = projectionAheadWindowM,
            onRouteThresholdM = offRouteThresholdM,
        )
        val recordRaceDistanceAtElapsed = route.distanceAtElapsed(runnerElapsedMs)
        val timeGapMs = projection.elapsedMs - runnerElapsedMs
        val rawDistanceGapM = projection.distanceAlongRouteM - recordRaceDistanceAtElapsed
        val isOffRoute = projection.distanceFromRouteM >= offRouteThresholdM
        val status = when {
            isOffRoute -> WearRecordRaceStatus.OffRoute
            kotlin.math.abs(timeGapMs) <= levelThresholdMs -> WearRecordRaceStatus.Level
            timeGapMs > 0L -> WearRecordRaceStatus.Ahead
            else -> WearRecordRaceStatus.Behind
        }
        val distanceGapM = if (kotlin.math.abs(rawDistanceGapM) <= levelDistanceThresholdM) {
            0.0
        } else {
            rawDistanceGapM
        }
        return WearRecordRaceFrame(
            status = status,
            timeGapMs = timeGapMs,
            distanceGapM = distanceGapM,
            routeProgress = route.progressFor(projection.distanceAlongRouteM),
            distanceToFinishM = route.distanceToFinish(projection.distanceAlongRouteM),
            distanceFromRouteM = projection.distanceFromRouteM,
            totalRouteDistanceM = route.totalDistanceM,
            distanceToFinishPointM = distanceBetween(runnerPoint, recordRaceConfig.points.last()),
            startConfirmed = startConfirmed,
            startCandidateCount = startCandidateCount,
            startLastEvaluatedPointCount = startLastEvaluatedPointCount,
            trackedDistanceAlongRouteM = if (startConfirmed) {
                projection.distanceAlongRouteM
            } else {
                previousDistanceAlongRouteM
            },
            projectionSource = projection.source,
        )
    }

    private data class RecordRaceRouteModel(val segments: List<RecordRaceRouteSegment>) {
        val totalDistanceM: Double
            get() = segments.lastOrNull()?.endDistanceM ?: 0.0

        fun projectGlobal(runnerPoint: WearRunPoint): RouteProjection {
            return segments
                .map { segment ->
                    segment.project(
                        runnerPoint,
                        source = WearRecordRaceProjectionSource.Global,
                    )
                }
                .minBy { projection -> projection.distanceFromRouteM }
        }

        fun projectWithinDistanceWindow(
            runnerPoint: WearRunPoint,
            minDistanceM: Double,
            maxDistanceM: Double,
        ): RouteProjection? {
            return segments
                .asSequence()
                .filter { segment ->
                    segment.endDistanceM >= minDistanceM &&
                        segment.startDistanceM <= maxDistanceM
                }
                .map { segment ->
                    segment.project(
                        runnerPoint,
                        source = WearRecordRaceProjectionSource.Tracked,
                    )
                }
                .filter { projection ->
                    projection.distanceAlongRouteM in minDistanceM..maxDistanceM
                }
                .minByOrNull { projection -> projection.distanceFromRouteM }
        }

        fun projectTracked(
            runnerPoint: WearRunPoint,
            previousDistanceAlongRouteM: Double?,
            behindWindowM: Double,
            aheadWindowM: Double,
            onRouteThresholdM: Double,
        ): RouteProjection {
            val globalProjection = projectGlobal(runnerPoint)
            val previous = previousDistanceAlongRouteM ?: return globalProjection
            val previousDistance = previous.coerceIn(0.0, totalDistanceM)
            val windowProjection = projectWithinDistanceWindow(
                runnerPoint = runnerPoint,
                minDistanceM = (previousDistance - behindWindowM).coerceIn(0.0, totalDistanceM),
                maxDistanceM = (previousDistance + aheadWindowM).coerceIn(0.0, totalDistanceM),
            )
            if (windowProjection != null &&
                windowProjection.distanceFromRouteM <= onRouteThresholdM
            ) {
                return windowProjection
            }
            return RouteProjection(
                distanceFromRouteM = globalProjection.distanceFromRouteM,
                distanceAlongRouteM = previousDistance,
                elapsedMs = elapsedAtDistance(previousDistance),
                source = WearRecordRaceProjectionSource.Held,
            )
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

        fun progressFor(distanceAlongRouteM: Double): Double {
            val total = totalDistanceM
            if (total <= 0.0) return 0.0
            return (distanceAlongRouteM / total).coerceIn(0.0, 1.0)
        }

        fun distanceToFinish(distanceAlongRouteM: Double): Double {
            return (totalDistanceM - distanceAlongRouteM).coerceAtLeast(0.0)
        }

        fun elapsedAtDistance(distanceAlongRouteM: Double): Long {
            val distance = distanceAlongRouteM.coerceIn(0.0, totalDistanceM)
            for (segment in segments) {
                if (distance > segment.endDistanceM) continue
                val segmentDistance = segment.endDistanceM - segment.startDistanceM
                if (segmentDistance <= 0.0) return segment.start.timestampRelMs
                val ratio = ((distance - segment.startDistanceM) / segmentDistance)
                    .coerceIn(0.0, 1.0)
                return segment.start.timestampRelMs +
                    ((segment.end.timestampRelMs - segment.start.timestampRelMs) * ratio)
                        .roundToLong()
            }
            return segments.last().end.timestampRelMs
        }

        companion object {
            fun from(points: List<WearRunPoint>): RecordRaceRouteModel {
                val segments = mutableListOf<RecordRaceRouteSegment>()
                var distanceBeforeM = 0.0
                for (index in 0 until points.lastIndex) {
                    val start = points[index]
                    val end = points[index + 1]
                    val distanceM = distanceBetween(start, end)
                    if (distanceM <= 0.0) continue
                    val segment = RecordRaceRouteSegment(
                        start = start,
                        end = end,
                        startDistanceM = distanceBeforeM,
                        endDistanceM = distanceBeforeM + distanceM,
                    )
                    segments.add(segment)
                    distanceBeforeM = segment.endDistanceM
                }
                return RecordRaceRouteModel(segments)
            }
        }
    }

    private data class RecordRaceRouteSegment(
        val start: WearRunPoint,
        val end: WearRunPoint,
        val startDistanceM: Double,
        val endDistanceM: Double,
    ) {
        fun project(
            runnerPoint: WearRunPoint,
            source: WearRecordRaceProjectionSource,
        ): RouteProjection {
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
                source = source,
            )
        }
    }

    private data class RouteProjection(
        val distanceFromRouteM: Double,
        val distanceAlongRouteM: Double,
        val elapsedMs: Long,
        val source: WearRecordRaceProjectionSource,
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

data class WearRecordRaceStartDecision(
    val isConfirmed: Boolean,
    val candidateCount: Int,
    val lastEvaluatedPointCount: Int,
)

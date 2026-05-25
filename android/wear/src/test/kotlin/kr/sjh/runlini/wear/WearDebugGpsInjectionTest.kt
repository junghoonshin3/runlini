package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WearDebugGpsInjectionTest {
    @Test
    fun mapperBuildsValidDebugSample() {
        val sample = WearDebugGpsSampleMapper.fromValues(
            latitude = 34.668446,
            longitude = 135.496953,
            elapsedMs = 12_000L,
            distanceM = 50.0,
            speedMps = 2.38,
            paceSecPerKm = 420.0,
            accuracyM = 5.0,
            elevationM = 0.0,
        )

        requireNotNull(sample)
        assertEquals(34.668446, sample.latitude, 0.000001)
        assertEquals(135.496953, sample.longitude, 0.000001)
        assertEquals(12_000L, sample.elapsedMs)
        assertEquals(50.0, sample.distanceM, 0.01)
    }

    @Test
    fun mapperRejectsInvalidDebugSample() {
        val sample = WearDebugGpsSampleMapper.fromValues(
            latitude = 134.0,
            longitude = 135.496953,
            elapsedMs = 12_000L,
            distanceM = 50.0,
            speedMps = 2.38,
            paceSecPerKm = 420.0,
            accuracyM = 5.0,
            elevationM = 0.0,
        )

        assertNull(sample)
    }

    @Test
    fun activeInjectionFiltersOnlyHealthServicesMotionMetrics() {
        val merger = WearDebugGpsInjectionMerger(timeoutMs = 10_000L)
        val injected = merger.recordInjectedSample(debugSample(), realtimeMs = 1_000L)

        assertEquals(12_000L, injected.activeDurationMs)
        assertEquals(50.0, injected.distanceM ?: 0.0, 0.01)
        assertEquals(1, injected.points.size)
        assertEquals(34.668446, injected.points.first().latitude, 0.000001)

        val filtered = merger.filterHealthServicesSample(
            WearMetricSample(
                activeDurationMs = 3_000L,
                distanceM = 999.0,
                paceSecPerKm = 300.0,
                speedMps = 3.3,
                cadenceSpm = 172.0,
                heartRateBpm = 145,
                caloriesKcal = 11.0,
                points = listOf(WearRunPoint(37.422, -122.084, 3_000L)),
            ),
            realtimeMs = 5_000L,
        )

        assertNull(filtered.activeDurationMs)
        assertNull(filtered.distanceM)
        assertNull(filtered.paceSecPerKm)
        assertNull(filtered.speedMps)
        assertEquals(emptyList<WearRunPoint>(), filtered.points)
        assertEquals(172.0, filtered.cadenceSpm ?: 0.0, 0.01)
        assertEquals(145, filtered.heartRateBpm)
        assertEquals(11.0, filtered.caloriesKcal ?: 0.0, 0.01)
    }

    @Test
    fun staleInjectionAllowsHealthServicesMotionAgain() {
        val merger = WearDebugGpsInjectionMerger(timeoutMs = 10_000L)
        merger.recordInjectedSample(debugSample(), realtimeMs = 1_000L)

        val sample = WearMetricSample(
            activeDurationMs = 14_000L,
            distanceM = 120.0,
            paceSecPerKm = 420.0,
            speedMps = 2.38,
            points = listOf(WearRunPoint(37.422, -122.084, 14_000L)),
        )
        val filtered = merger.filterHealthServicesSample(sample, realtimeMs = 11_001L)

        assertEquals(14_000L, filtered.activeDurationMs)
        assertEquals(120.0, filtered.distanceM ?: 0.0, 0.01)
        assertEquals(1, filtered.points.size)
    }

    @Test
    fun injectedOsakaPointCanMatchRecordRaceRoute() {
        val config = WearRecordRaceConfig(
            id = "osaka",
            durationMs = 60_000L,
            distanceM = 100.0,
            sourceSummary = "fixture",
            points = listOf(
                WearRunPoint(34.668446, 135.496953, 0L),
                WearRunPoint(34.668781, 135.496668, 60_000L),
            ),
        )
        val frame = WearRecordRaceGapCalculator().calculate(
            runnerPoint = WearDebugGpsInjectionMerger()
                .recordInjectedSample(debugSample(), realtimeMs = 1_000L)
                .points
                .first(),
            recordRaceConfig = config,
            runnerElapsedMs = 12_000L,
        )

        assertNotEquals(WearRecordRaceStatus.OffRoute, frame.status)
    }

    private fun debugSample(): WearDebugGpsSample {
        return WearDebugGpsSample(
            latitude = 34.668446,
            longitude = 135.496953,
            elapsedMs = 12_000L,
            distanceM = 50.0,
            speedMps = 2.38,
            paceSecPerKm = 420.0,
            accuracyM = 5.0,
            elevationM = 0.0,
        )
    }
}

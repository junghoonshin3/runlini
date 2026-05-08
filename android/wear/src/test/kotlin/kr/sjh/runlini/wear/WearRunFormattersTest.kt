package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Test

class WearRunFormattersTest {
    @Test
    fun formatsElapsedDistancePaceAndGhostGapForWatch() {
        assertEquals("01:05", WearRunFormatters.elapsed(65_000L))
        assertEquals("1:01:05", WearRunFormatters.elapsed(3_665_000L))
        assertEquals("1.23 km", WearRunFormatters.distance(1_234.0))
        assertEquals(
            WearDistanceHeroText("1.23", "km"),
            WearRunFormatters.distanceHero(1_234.0),
        )
        assertEquals("5:07/km", WearRunFormatters.pace(307.0))
        assertEquals("12.0 km/h", WearRunFormatters.speed(3.333))
        assertEquals("172 spm", WearRunFormatters.cadence(171.6))
        assertEquals("+0:12", WearRunFormatters.ghostGap(ghostFrame(12_000L)))
        assertEquals("-1:05", WearRunFormatters.ghostGap(ghostFrame(-65_000L)))
        assertEquals("72%", WearRunFormatters.ghostProgress(ghostFrame(12_000L)))
        assertEquals("420 m", WearRunFormatters.ghostRemaining(ghostFrame(12_000L)))
    }

    @Test
    fun formatsMissingMetricsAsDashes() {
        assertEquals("--", WearRunFormatters.pace(null))
        assertEquals("--", WearRunFormatters.speed(null))
        assertEquals("--", WearRunFormatters.cadence(null))
        assertEquals("--", WearRunFormatters.heartRate(null))
        assertEquals("--", WearRunFormatters.calories(null))
        assertEquals("--", WearRunFormatters.ghostGap(null))
        assertEquals("--", WearRunFormatters.ghostProgress(null))
        assertEquals("--", WearRunFormatters.ghostRemaining(null))
    }

    @Test
    fun distanceHeroTypographyShrinksForLongValues() {
        assertEquals(
            38,
            WearDistanceHeroTypography.valueSizeSp("0.01", WearLayoutProfile.Compact),
        )
        assertEquals(
            34,
            WearDistanceHeroTypography.valueSizeSp("12.10", WearLayoutProfile.Compact),
        )
        assertEquals(
            30,
            WearDistanceHeroTypography.valueSizeSp("100.00", WearLayoutProfile.Compact),
        )
        assertEquals(
            44,
            WearDistanceHeroTypography.valueSizeSp("0.01", WearLayoutProfile.Regular),
        )
        assertEquals(
            39,
            WearDistanceHeroTypography.valueSizeSp("42.20", WearLayoutProfile.Regular),
        )
        assertEquals(
            34,
            WearDistanceHeroTypography.valueSizeSp("100.00", WearLayoutProfile.Regular),
        )
    }

    private fun ghostFrame(gapMs: Long): WearGhostFrame {
        return WearGhostFrame(
            status = WearGhostStatus.Ahead,
            timeGapMs = gapMs,
            distanceGapM = 24.0,
            routeProgress = 0.72,
            distanceToFinishM = 420.0,
        )
    }
}

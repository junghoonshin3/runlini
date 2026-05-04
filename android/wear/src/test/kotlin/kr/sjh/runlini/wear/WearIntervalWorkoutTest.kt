package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WearIntervalWorkoutTest {
    @Test
    fun mapperRoundTripsIntervalWorkout() {
        val workout = WearIntervalWorkout(
            enabled = true,
            warmup = WearIntervalTarget(WearIntervalTargetType.Open),
            work = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 60_000L),
            recovery = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 200.0),
            repeatCount = 6,
            cooldown = WearIntervalTarget(WearIntervalTargetType.Skip),
        )

        val restored = WearIntervalWorkoutJsonMapper.fromJson(
            WearIntervalWorkoutJsonMapper.toJson(workout),
        )

        assertTrue(restored.enabled)
        assertEquals(WearIntervalTargetType.Open, restored.warmup.type)
        assertEquals(60_000L, restored.work.durationMs)
        assertEquals(200.0, restored.recovery.distanceM!!, 0.001)
        assertEquals(6, restored.repeatCount)
        assertEquals(WearIntervalTargetType.Skip, restored.cooldown.type)
    }

    @Test
    fun calculatorProgressesThroughRepeatedSteps() {
        val workout = WearIntervalWorkout(
            enabled = true,
            warmup = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 5_000L),
            work = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 1_000L),
            recovery = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 2_000L),
            repeatCount = 2,
            cooldown = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 3_000L),
        )
        val calculator = WearIntervalWorkoutCalculator()

        assertEquals(
            "워밍업",
            WearIntervalFormatters.stepLabel(
                calculator.calculate(workout, elapsedMs = 0, distanceM = 0.0)?.step,
            ),
        )
        assertEquals(
            "질주 1/2",
            WearIntervalFormatters.stepLabel(
                calculator.calculate(workout, elapsedMs = 5_200L, distanceM = 0.0)?.step,
            ),
        )
        assertEquals(
            "휴식 1/2",
            WearIntervalFormatters.stepLabel(
                calculator.calculate(workout, elapsedMs = 6_500L, distanceM = 0.0)?.step,
            ),
        )
        assertEquals(
            "쿨다운",
            WearIntervalFormatters.stepLabel(
                calculator.calculate(workout, elapsedMs = 11_000L, distanceM = 0.0)?.step,
            ),
        )
    }

    @Test
    fun calculatorReturnsNullWhenDisabled() {
        assertNull(
            WearIntervalWorkoutCalculator().calculate(
                workout = WearIntervalWorkout(enabled = false),
                elapsedMs = 0,
                distanceM = 0.0,
            ),
        )
    }

    @Test
    fun settingsMapperKeepsIntervalConfig() {
        val settings = WearRunSettings(
            intervalWorkout = WearIntervalWorkout(enabled = true, repeatCount = 4),
        )

        val restored = WearRunSettingsJsonMapper.fromJson(
            WearRunSettingsJsonMapper.toJson(settings),
        )

        assertNotNull(restored.intervalWorkout)
        assertTrue(restored.intervalWorkout.enabled)
        assertEquals(4, restored.intervalWorkout.repeatCount)
    }

    @Test
    fun quickSettingsStepsTimeAndDistanceTargetsDirectly() {
        val workout = WearIntervalWorkout(
            enabled = true,
            work = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 60_000L),
            recovery = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 400.0),
            repeatCount = 8,
        )

        val workDistance = WearIntervalQuickSettings.toggleTargetType(
            workout.work,
            isWork = true,
        )
        val recoveryTime = WearIntervalQuickSettings.toggleTargetType(
            workout.recovery,
            isWork = false,
        )

        assertEquals(WearIntervalTargetType.Distance, workDistance.type)
        assertEquals(400.0, workDistance.distanceM!!, 0.001)
        assertEquals(WearIntervalTargetType.Time, recoveryTime.type)
        assertEquals(60_000L, recoveryTime.durationMs)

        val longerWork = WearIntervalQuickSettings.stepTarget(
            workout.work,
            isWork = true,
            delta = 1,
        )
        val shorterWork = WearIntervalQuickSettings.stepTarget(
            workout.work,
            isWork = true,
            delta = -1,
        )
        val longerRecovery = WearIntervalQuickSettings.stepTarget(
            workout.recovery,
            isWork = false,
            delta = 1,
        )
        val shorterRecovery = WearIntervalQuickSettings.stepTarget(
            workout.recovery,
            isWork = false,
            delta = -1,
        )

        assertEquals(70_000L, longerWork.durationMs)
        assertEquals(50_000L, shorterWork.durationMs)
        assertEquals(450.0, longerRecovery.distanceM!!, 0.001)
        assertEquals(350.0, shorterRecovery.distanceM!!, 0.001)
        assertEquals(9, WearIntervalQuickSettings.stepRepeat(8, 1))
        assertEquals(1, WearIntervalQuickSettings.stepRepeat(1, -1))
        assertEquals(30, WearIntervalQuickSettings.stepRepeat(30, 1))
    }

    @Test
    fun quickSettingsClampsDirectStepperRanges() {
        val minTime = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 10_000L)
        val maxTime = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 1_800_000L)
        val minDistance = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 50.0)
        val maxDistance = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 10_000.0)

        assertEquals(
            10_000L,
            WearIntervalQuickSettings.stepTarget(minTime, isWork = true, delta = -1).durationMs,
        )
        assertEquals(
            1_800_000L,
            WearIntervalQuickSettings.stepTarget(maxTime, isWork = true, delta = 1).durationMs,
        )
        assertEquals(
            50.0,
            WearIntervalQuickSettings.stepTarget(
                minDistance,
                isWork = true,
                delta = -1,
            ).distanceM!!,
            0.001,
        )
        assertEquals(
            10_000.0,
            WearIntervalQuickSettings.stepTarget(
                maxDistance,
                isWork = true,
                delta = 1,
            ).distanceM!!,
            0.001,
        )
    }

    @Test
    fun quickSettingsKeepsCustomSyncedValuesAsStepperBaseline() {
        val customTime = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 80_000L)
        val customDistance = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 750.0)

        assertEquals(
            90_000L,
            WearIntervalQuickSettings.stepTarget(customTime, isWork = true, delta = 1).durationMs,
        )
        assertEquals(
            700.0,
            WearIntervalQuickSettings.stepTarget(
                customDistance,
                isWork = true,
                delta = -1,
            ).distanceM!!,
            0.001,
        )
    }

    @Test
    fun distanceIntervalFrameReportsRemainingDistance() {
        val workout = WearIntervalWorkout(
            enabled = true,
            warmup = WearIntervalTarget(WearIntervalTargetType.Skip),
            work = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 400.0),
            recovery = WearIntervalTarget(WearIntervalTargetType.Distance, distanceM = 200.0),
            repeatCount = 1,
            cooldown = WearIntervalTarget(WearIntervalTargetType.Skip),
        )

        val frame = WearIntervalWorkoutCalculator().calculate(
            workout = workout,
            elapsedMs = 30_000L,
            distanceM = 150.0,
        )

        assertEquals("질주 1/1", WearIntervalFormatters.stepLabel(frame?.step))
        assertEquals("남은 250m", WearIntervalFormatters.remaining(frame))
        assertEquals("400m", WearIntervalFormatters.target(workout.work))
        assertEquals(
            "휴식 1/1",
            WearIntervalFormatters.stepLabel(frame?.nextStep),
        )
    }

    @Test
    fun heroFormatterSplitsRemainingLabelAndValue() {
        val timeHero = WearIntervalFormatters.heroRemaining(
            intervalFrame(remainingMs = 30_000L),
        )
        val shortDistanceHero = WearIntervalFormatters.heroRemaining(
            intervalFrame(remainingM = 250.0),
        )
        val longDistanceHero = WearIntervalFormatters.heroRemaining(
            intervalFrame(remainingM = 1_234.0),
        )

        assertEquals(WearIntervalHeroText("남은 시간", "30초"), timeHero)
        assertEquals(WearIntervalHeroText("남은 거리", "250m"), shortDistanceHero)
        assertEquals(WearIntervalHeroText("남은 거리", "1.2km"), longDistanceHero)
        assertEquals("남은 30초", WearIntervalFormatters.remaining(intervalFrame(remainingMs = 30_000L)))
    }

    @Test
    fun intervalHeroTypographyShrinksForLongValues() {
        assertEquals(
            48,
            WearIntervalHeroTypography.valueSizeSp("30초", WearLayoutProfile.Compact),
        )
        assertEquals(
            42,
            WearIntervalHeroTypography.valueSizeSp("1.2km", WearLayoutProfile.Compact),
        )
        assertEquals(
            36,
            WearIntervalHeroTypography.valueSizeSp("10.0km", WearLayoutProfile.Compact),
        )
    }

    private fun intervalFrame(
        remainingMs: Long? = null,
        remainingM: Double? = null,
    ): WearIntervalFrame {
        return WearIntervalFrame(
            step = WearIntervalStep(
                kind = WearIntervalStepKind.Recovery,
                target = WearIntervalTarget(WearIntervalTargetType.Time, durationMs = 60_000L),
                repeatIndex = 1,
                repeatCount = 3,
            ),
            nextStep = null,
            remainingMs = remainingMs,
            remainingM = remainingM,
            progress = 0.5,
        )
    }
}

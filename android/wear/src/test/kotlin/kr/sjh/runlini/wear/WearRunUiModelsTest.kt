package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WearRunUiModelsTest {
    @Test
    fun pageModelUsesThreePagesForNormalRuns() {
        val pages = WearActiveRunPageModel.pagesFor(WearRunState())

        assertEquals(
            listOf(
                WearActiveRunPage.Core,
                WearActiveRunPage.Details,
                WearActiveRunPage.Controls,
            ),
            pages,
        )
    }

    @Test
    fun pageModelInsertsGhostPageForGhostRuns() {
        val pages = WearActiveRunPageModel.pagesFor(
            WearRunState(isGhostRun = true, ghostConfig = ghostConfig()),
        )

        assertEquals(
            listOf(
                WearActiveRunPage.Core,
                WearActiveRunPage.Ghost,
                WearActiveRunPage.Details,
                WearActiveRunPage.Controls,
            ),
            pages,
        )
    }

    @Test
    fun readyModelPrioritizesGhostStartWhenGhostIsCached() {
        val model = WearReadyScreenModelBuilder.from(
            WearRunState(
                ghostConfig = ghostConfig(),
                pendingDraftCount = 2,
                statusMessage = "준비 완료",
            ),
        )

        assertEquals("GHOST\nSTART", model.primaryLabel)
        assertTrue(model.usesGhostPrimary)
        assertEquals("일반 시작", model.secondaryLabel)
        assertEquals("전송 대기 2개", model.pendingLabel)
        assertEquals("다시 보내기", model.retryLabel)
        assertEquals("한강 5K", model.ghostLabel)
        assertFalse(model.isError)
    }

    @Test
    fun readyModelUsesNormalStartWithoutGhost() {
        val model = WearReadyScreenModelBuilder.from(WearRunState())

        assertEquals("START", model.primaryLabel)
        assertFalse(model.usesGhostPrimary)
        assertNull(model.secondaryLabel)
        assertNull(model.pendingLabel)
        assertNull(model.ghostLabel)
    }

    @Test
    fun reviewSummaryIncludesGhostResultWhenPresent() {
        val model = WearReviewSummaryModelBuilder.from(
            WearRunState(
                elapsedMs = 600_000L,
                distanceM = 2_000.0,
                averagePaceSecPerKm = 300.0,
                caloriesKcal = 123.0,
                isGhostRun = true,
                ghostConfig = ghostConfig(),
                ghostFrame = WearGhostFrame(
                    status = WearGhostStatus.Behind,
                    timeGapMs = -8_000L,
                    distanceGapM = -12.0,
                ),
            ),
        )

        assertEquals("10:00", model.elapsed)
        assertEquals("2.00 km", model.distance)
        assertEquals("5:00/km", model.averagePace)
        assertEquals("123 kcal", model.calories)
        assertEquals("뒤처지는 중 -0:08", model.ghostResult)
    }

    private fun ghostConfig(): WearGhostConfig {
        return WearGhostConfig(
            id = "ghost-1",
            durationMs = 1_800_000L,
            distanceM = 5_000.0,
            sourceSummary = "한강 5K",
            points = listOf(
                WearRunPoint(
                    latitude = 37.0,
                    longitude = 127.0,
                    timestampRelMs = 0L,
                ),
                WearRunPoint(
                    latitude = 37.001,
                    longitude = 127.001,
                    timestampRelMs = 60_000L,
                ),
            ),
        )
    }
}

package kr.sjh.runlini.wear

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class WearRunUiModelsTest {
    @Test
    fun layoutProfileUsesCompactBelowRegularBreakpoint() {
        assertEquals(WearLayoutProfile.Compact, WearRunLayoutModel.profileFor(192, 192))
        assertEquals(WearLayoutProfile.Compact, WearRunLayoutModel.profileFor(224, 300))
    }

    @Test
    fun layoutProfileUsesRegularAtRegularBreakpoint() {
        assertEquals(WearLayoutProfile.Regular, WearRunLayoutModel.profileFor(225, 225))
        assertEquals(WearLayoutProfile.Regular, WearRunLayoutModel.profileFor(260, 260))
    }

    @Test
    fun readyPageModelAlwaysIncludesRecordRacePicker() {
        val pages = WearReadyPageModel.pagesFor(WearRunState())

        assertEquals(listOf(WearReadyPage.Ready, WearReadyPage.RecordRaces, WearReadyPage.Settings), pages)
        assertEquals(0, WearReadyPageModel.initialPageFor(pages))
    }

    @Test
    fun readyPageModelAddsRecordRacePickerWhenAnyRecordRaceIsCached() {
        val pages = WearReadyPageModel.pagesFor(
            WearRunState(
                recordRaceConfig = recordRaceConfig("record-race-1"),
                recordRaceConfigs = listOf(recordRaceConfig("record-race-1")),
            ),
        )

        assertEquals(listOf(WearReadyPage.Ready, WearReadyPage.RecordRaces, WearReadyPage.Settings), pages)
        assertEquals(0, WearReadyPageModel.initialPageFor(pages))
    }

    @Test
    fun pageModelUsesThreePagesForNormalRuns() {
        val pages = WearActiveRunPageModel.pagesFor(WearRunState())

        assertEquals(
            listOf(
                WearActiveRunPage.Controls,
                WearActiveRunPage.Core,
                WearActiveRunPage.Details,
            ),
            pages,
        )
    }

    @Test
    fun pageModelInsertsRecordRacePageForRecordRaceRuns() {
        val pages = WearActiveRunPageModel.pagesFor(
            WearRunState(isRecordRaceRun = true, recordRaceConfig = recordRaceConfig()),
        )

        assertEquals(
            listOf(
                WearActiveRunPage.Controls,
                WearActiveRunPage.Core,
                WearActiveRunPage.RecordRace,
                WearActiveRunPage.Details,
            ),
            pages,
        )
    }

    @Test
    fun pageModelInsertsIntervalPageWhenEnabled() {
        val pages = WearActiveRunPageModel.pagesFor(
            WearRunState(
                settings = WearRunSettings(
                    intervalWorkout = WearIntervalWorkout(enabled = true),
                ),
            ),
        )

        assertEquals(
            listOf(
                WearActiveRunPage.Controls,
                WearActiveRunPage.Core,
                WearActiveRunPage.Interval,
                WearActiveRunPage.Details,
            ),
            pages,
        )
    }

    @Test
    fun pageModelHidesIntervalPageForRecordRaceRuns() {
        val pages = WearActiveRunPageModel.pagesFor(
            WearRunState(
                isRecordRaceRun = true,
                recordRaceConfig = recordRaceConfig(),
                settings = WearRunSettings(
                    intervalWorkout = WearIntervalWorkout(enabled = true),
                ),
            ),
        )

        assertEquals(
            listOf(
                WearActiveRunPage.Controls,
                WearActiveRunPage.Core,
                WearActiveRunPage.RecordRace,
                WearActiveRunPage.Details,
            ),
            pages,
        )
    }

    @Test
    fun pageModelStartsActivePagerOnCorePage() {
        val pages = WearActiveRunPageModel.pagesFor(WearRunState())

        assertEquals(1, WearActiveRunPageModel.initialPageFor(pages))
    }

    @Test
    fun runningControlModelUsesPauseAndStopIcons() {
        val model = WearRunControlModelBuilder.from(
            WearRunState(phase = WearRunPhase.Running),
        )

        assertEquals("일시정지", model.primaryLabel)
        assertEquals(WearRunButtonIcon.Pause, model.primaryIcon)
        assertFalse(model.primaryIsResume)
        assertEquals("중지", model.secondaryLabel)
        assertEquals(WearRunButtonIcon.Stop, model.secondaryIcon)
        assertTrue(model.secondaryIsDestructive)
    }

    @Test
    fun pausedControlModelStaysInHubAndUsesResumeAction() {
        val model = WearRunControlModelBuilder.from(
            WearRunState(phase = WearRunPhase.Paused),
        )

        assertEquals("재개", model.primaryLabel)
        assertEquals(WearRunButtonIcon.Play, model.primaryIcon)
        assertTrue(model.primaryIsResume)
        assertEquals("중지", model.secondaryLabel)
        assertEquals(WearRunButtonIcon.Stop, model.secondaryIcon)
    }

    @Test
    fun readyModelPrioritizesRecordRaceStartWhenRecordRaceIsCached() {
        val model = WearReadyScreenModelBuilder.from(
            WearRunState(
                recordRaceConfig = recordRaceConfig(),
                pendingDraftCount = 2,
                statusMessage = "준비 완료",
            ),
        )

        assertEquals("기록 레이스\n시작", model.primaryLabel)
        assertTrue(model.usesRecordRacePrimary)
        assertEquals("일반 시작", model.secondaryLabel)
        assertEquals("한강 5K", model.recordRaceLabel)
        assertEquals(1, model.recordRaceCount)
        assertFalse(model.isError)
    }

    @Test
    fun recordRaceReadyActionModelShowsCachedRecordRaceCount() {
        val readyModel = WearReadyScreenModelBuilder.from(
            WearRunState(
                recordRaceConfig = recordRaceConfig("record-race-1"),
                recordRaceConfigs = listOf(recordRaceConfig("record-race-1"), recordRaceConfig("record-race-2")),
            ),
        )

        val actionModel = WearRecordRaceReadyModelBuilder.actionsFrom(readyModel)

        assertEquals("기록 레이스 2개", actionModel.statusLabel)
    }

    @Test
    fun recordRacePickerModelShowsOnlyThreeConciseOptions() {
        val model = WearRecordRacePickerModelBuilder.from(
            WearRunState(
                recordRaceConfig = recordRaceConfig("record-race-2"),
                recordRaceConfigs = listOf(
                    recordRaceConfig("record-race-1", sourceSummary = "device:gps"),
                    recordRaceConfig("record-race-2", sourceSummary = "한강 5K 빠른 기록"),
                    recordRaceConfig("record-race-3", sourceSummary = "남산"),
                    recordRaceConfig("record-race-4", sourceSummary = "초과"),
                ),
            ),
        )

        assertEquals(3, model.items.size)
        assertEquals("기록 레이스 1", model.items[0].label)
        assertEquals("한강 5K 빠른 기", model.items[1].label)
        assertEquals(true, model.items[1].isSelected)
        assertEquals("5.00 km", model.items[0].distance)
        assertEquals("30:00", model.items[0].elapsed)
    }

    @Test
    fun recordRacePickerModelShowsEmptyLabelWhenNoRecordRacesAreCached() {
        val model = WearRecordRacePickerModelBuilder.from(WearRunState())

        assertEquals(emptyList<WearRecordRacePickerItemModel>(), model.items)
        assertEquals("없음", model.emptyLabel)
    }

    @Test
    fun recordRaceReadyActionModelHidesSourceSummary() {
        val readyModel = WearReadyScreenModelBuilder.from(
            WearRunState(
                recordRaceConfig = recordRaceConfig().copy(sourceSummary = "device:gps"),
            ),
        )

        val actionModel = WearRecordRaceReadyModelBuilder.actionsFrom(readyModel)

        assertEquals("기록 레이스\n시작", actionModel.recordRaceStartLabel)
        assertEquals("일반\n시작", actionModel.normalStartLabel)
        assertEquals("기록 레이스 모드 ON", actionModel.statusLabel)
        assertFalse(actionModel.statusLabel.contains("device:gps"))
        assertFalse(actionModel.isError)
    }

    @Test
    fun recordRaceReadyActionModelPrioritizesErrorStatus() {
        val readyModel = WearReadyScreenModelBuilder.from(
            WearRunState(
                recordRaceConfig = recordRaceConfig(),
                errorMessage = "센서 오류",
            ),
        )

        val actionModel = WearRecordRaceReadyModelBuilder.actionsFrom(readyModel)

        assertEquals("오류", actionModel.statusLabel)
        assertTrue(actionModel.isError)
    }

    @Test
    fun recordRaceReadyCompactActionsFitSmallRoundScreen() {
        val layout = WearRecordRaceReadyModelBuilder.layoutFor(WearLayoutProfile.Compact)

        assertEquals(64, layout.circleSizeDp)
        assertEquals(8, layout.gapDp)
        assertEquals(12, layout.labelSizeSp)
        assertEquals(19, layout.titleSizeSp)
        assertTrue(WearRecordRaceReadyModelBuilder.actionRowFits(widthDp = 192, heightDp = 192))
    }

    @Test
    fun voiceVolumeControlsKeepFixedWidthAtOneHundredPercent() {
        val zeroWidth = WearVolumeRowLayoutModel.controlWidthFor(0.0f)
        val ninetyWidth = WearVolumeRowLayoutModel.controlWidthFor(0.9f)
        val fullWidth = WearVolumeRowLayoutModel.controlWidthFor(1.0f)

        assertEquals(zeroWidth, ninetyWidth)
        assertEquals(ninetyWidth, fullWidth)
        assertEquals(98, fullWidth)
        assertTrue(
            WearVolumeRowLayoutModel.valueSlotCanShow(
                WearVolumeRowLayoutModel.percentLabel(1.0f),
            ),
        )
    }

    @Test
    fun readyModelIgnoresPendingDraftsAndCompletionMessages() {
        val model = WearReadyScreenModelBuilder.from(
            WearRunState(
                pendingDraftCount = 3,
                statusMessage = "저장됨",
            ),
        )

        assertEquals("시작", model.primaryLabel)
        assertEquals("준비 완료", model.statusLabel)
        assertFalse(model.usesRecordRacePrimary)
        assertNull(model.secondaryLabel)
    }

    @Test
    fun readyModelUsesNormalStartWithoutRecordRace() {
        val model = WearReadyScreenModelBuilder.from(WearRunState())

        assertEquals("시작", model.primaryLabel)
        assertFalse(model.usesRecordRacePrimary)
        assertNull(model.secondaryLabel)
        assertNull(model.recordRaceLabel)
    }

    @Test
    fun countdownModelUsesNormalReadyLabel() {
        val model = WearCountdownModelBuilder.from(
            WearRunState(
                phase = WearRunPhase.CountingDown,
                countdownRemainingSeconds = 3,
            ),
        )

        assertEquals("준비", model.label)
        assertEquals("3", model.remainingSeconds)
    }

    @Test
    fun countdownModelUsesRecordRaceReadyLabelAndClampsNumber() {
        val model = WearCountdownModelBuilder.from(
            WearRunState(
                phase = WearRunPhase.CountingDown,
                countdownRemainingSeconds = 4,
                countdownStartRecordRaceConfig = recordRaceConfig(),
            ),
        )

        assertEquals("기록 레이스 준비", model.label)
        assertEquals("3", model.remainingSeconds)
    }

    @Test
    fun completionFeedbackModelUsesSavedLabel() {
        val model = WearCompletionFeedbackModelBuilder.from(
            WearRunState(
                phase = WearRunPhase.Feedback,
                feedbackType = WearRunFeedbackType.Saved,
            ),
        )

        assertEquals("저장 완료", model.label)
        assertFalse(model.isDestructive)
    }

    @Test
    fun completionFeedbackModelUsesDiscardedLabel() {
        val model = WearCompletionFeedbackModelBuilder.from(
            WearRunState(
                phase = WearRunPhase.Feedback,
                feedbackType = WearRunFeedbackType.Discarded,
            ),
        )

        assertEquals("삭제 완료", model.label)
        assertTrue(model.isDestructive)
    }

    @Test
    fun reviewSummaryIncludesRecordRaceResultWhenPresent() {
        val model = WearReviewSummaryModelBuilder.from(
            WearRunState(
                elapsedMs = 600_000L,
                distanceM = 2_000.0,
                averagePaceSecPerKm = 300.0,
                heartRateBpm = 156,
                averageCadenceSpm = 171.8,
                caloriesKcal = 123.0,
                speedMps = 3.33,
                pendingDraftCount = 1,
                isRecordRaceRun = true,
                recordRaceConfig = recordRaceConfig(),
                recordRaceFrame = WearRecordRaceFrame(
                    status = WearRecordRaceStatus.Behind,
                    timeGapMs = -8_000L,
                    distanceGapM = -12.0,
                ),
            ),
        )

        assertEquals("10:00", model.elapsed)
        assertEquals("2.00 km", model.distance)
        assertEquals("5:00/km", model.averagePace)
        assertEquals("172 spm", model.averageCadence)
        assertEquals("123 kcal", model.calories)
        assertEquals("156 bpm", model.heartRate)
        assertEquals("12.0 km/h", model.speed)
        assertEquals("뒤처지는 중 -0:08", model.recordRaceResult)
        assertEquals("전송 대기 1개", model.pendingLabel)
        assertEquals(
            listOf(
                WearReviewMetric("칼로리", "123 kcal"),
                WearReviewMetric("심박수", "156 bpm"),
                WearReviewMetric("케이던스", "172 spm"),
                WearReviewMetric("속도", "12.0 km/h"),
                WearReviewMetric("동기화", "전송 대기 1개"),
            ),
            model.detailMetrics,
        )
    }

    @Test
    fun reviewSummaryHidesRecordRaceResultForNormalRun() {
        val model = WearReviewSummaryModelBuilder.from(
            WearRunState(
                elapsedMs = 180_000L,
                distanceM = 600.0,
                averagePaceSecPerKm = 300.0,
                heartRateBpm = null,
                averageCadenceSpm = null,
                caloriesKcal = null,
                speedMps = null,
                isRecordRaceRun = false,
            ),
        )

        assertNull(model.recordRaceResult)
        assertNull(model.pendingLabel)
        assertEquals("--", model.heartRate)
        assertEquals("--", model.averageCadence)
        assertEquals("--", model.calories)
        assertEquals("--", model.speed)
        assertEquals(
            listOf(
                WearReviewMetric("칼로리", "--"),
                WearReviewMetric("심박수", "--"),
                WearReviewMetric("케이던스", "--"),
                WearReviewMetric("속도", "--"),
            ),
            model.detailMetrics,
        )
    }

    @Test
    fun reviewSummaryHidesRecordRaceResultUntilRecordRaceFrameExists() {
        val model = WearReviewSummaryModelBuilder.from(
            WearRunState(
                isRecordRaceRun = true,
                recordRaceConfig = recordRaceConfig(),
                recordRaceFrame = null,
            ),
        )

        assertNull(model.recordRaceResult)
    }

    private fun recordRaceConfig(
        id: String = "record-race-1",
        sourceSummary: String = "한강 5K",
    ): WearRecordRaceConfig {
        return WearRecordRaceConfig(
            id = id,
            durationMs = 1_800_000L,
            distanceM = 5_000.0,
            sourceSummary = sourceSummary,
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

package kr.sjh.runlini.wear

internal enum class WearActiveRunPage { Core, Interval, RecordRace, Details, Controls }

internal enum class WearReadyPage { Ready, RecordRaces, Settings }

internal object WearReadyPageModel {
    fun pagesFor(state: WearRunState): List<WearReadyPage> {
        return listOf(WearReadyPage.Ready, WearReadyPage.RecordRaces, WearReadyPage.Settings)
    }

    fun initialPageFor(pages: List<WearReadyPage>): Int {
        return pages.indexOf(WearReadyPage.Ready).coerceAtLeast(0)
    }
}

internal object WearActiveRunPageModel {
    fun pagesFor(state: WearRunState): List<WearActiveRunPage> {
        return buildList {
            add(WearActiveRunPage.Controls)
            add(WearActiveRunPage.Core)
            if (!state.isRecordRaceRun && state.settings.intervalWorkout.enabled) {
                add(WearActiveRunPage.Interval)
            }
            if (state.isRecordRaceRun) {
                add(WearActiveRunPage.RecordRace)
            }
            add(WearActiveRunPage.Details)
        }
    }

    fun initialPageFor(pages: List<WearActiveRunPage>): Int {
        return pages.indexOf(WearActiveRunPage.Core).coerceAtLeast(0)
    }
}

internal data class WearReadyScreenModel(
    val primaryLabel: String,
    val usesRecordRacePrimary: Boolean,
    val secondaryLabel: String?,
    val statusLabel: String,
    val isError: Boolean,
    val recordRaceLabel: String?,
    val recordRaceCount: Int,
)

internal data class WearRecordRaceReadyActionModel(
    val recordRaceStartLabel: String,
    val normalStartLabel: String,
    val statusLabel: String,
    val isError: Boolean,
)

internal data class WearRecordRaceReadyLayoutSpec(
    val circleSizeDp: Int,
    val gapDp: Int,
    val labelSizeSp: Int,
    val titleSizeSp: Int,
) {
    val actionRowWidthDp: Int = (circleSizeDp * 2) + gapDp
}

internal object WearRecordRaceReadyModelBuilder {
    fun actionsFrom(model: WearReadyScreenModel): WearRecordRaceReadyActionModel {
        return WearRecordRaceReadyActionModel(
            recordRaceStartLabel = "기록 레이스\n시작",
            normalStartLabel = "일반\n시작",
            statusLabel = when {
                model.isError -> "오류"
                model.recordRaceCount >= 2 -> "기록 레이스 ${model.recordRaceCount}개"
                else -> "기록 레이스 모드 ON"
            },
            isError = model.isError,
        )
    }

    fun layoutFor(profile: WearLayoutProfile): WearRecordRaceReadyLayoutSpec {
        return when (profile) {
            WearLayoutProfile.Compact -> WearRecordRaceReadyLayoutSpec(
                circleSizeDp = 64,
                gapDp = 8,
                labelSizeSp = 12,
                titleSizeSp = 19,
            )
            WearLayoutProfile.Regular -> WearRecordRaceReadyLayoutSpec(
                circleSizeDp = 76,
                gapDp = 12,
                labelSizeSp = 13,
                titleSizeSp = 23,
            )
        }
    }

    fun actionRowFits(widthDp: Int, heightDp: Int): Boolean {
        val profile = WearRunLayoutModel.profileFor(widthDp, heightDp)
        val horizontalPaddingRatio = if (profile == WearLayoutProfile.Compact) {
            0.24
        } else {
            0.20
        }
        val safeContentWidth = widthDp * (1.0 - horizontalPaddingRatio)
        return layoutFor(profile).actionRowWidthDp <= safeContentWidth
    }
}

internal data class WearRecordRacePickerItemModel(
    val id: String,
    val label: String,
    val distance: String,
    val elapsed: String,
    val isSelected: Boolean,
)

internal data class WearRecordRacePickerModel(
    val items: List<WearRecordRacePickerItemModel>,
    val emptyLabel: String?,
)

internal object WearRecordRacePickerModelBuilder {
    fun from(state: WearRunState): WearRecordRacePickerModel {
        val activeId = state.recordRaceConfig?.id
        return WearRecordRacePickerModel(
            items = state.recordRaceConfigs.take(3).mapIndexed { index, config ->
                WearRecordRacePickerItemModel(
                    id = config.id,
                    label = shortLabel(config.sourceSummary, index),
                    distance = WearRunFormatters.distance(config.distanceM),
                    elapsed = WearRunFormatters.elapsed(config.durationMs),
                    isSelected = config.id == activeId,
                )
            },
            emptyLabel = if (state.recordRaceConfigs.isEmpty()) "없음" else null,
        )
    }

    private fun shortLabel(sourceSummary: String, index: Int): String {
        val fallback = "기록 레이스 ${index + 1}"
        val cleaned = sourceSummary.trim()
        if (cleaned.isBlank() || cleaned.startsWith("device:")) {
            return fallback
        }
        return cleaned.take(10)
    }
}

internal data class WearCountdownModel(
    val label: String,
    val remainingSeconds: String,
)

internal object WearCountdownModelBuilder {
    fun from(state: WearRunState): WearCountdownModel {
        return WearCountdownModel(
            label = if (state.countdownStartRecordRaceConfig != null) "기록 레이스 준비" else "준비",
            remainingSeconds = (state.countdownRemainingSeconds ?: 3)
                .coerceIn(1, 3)
                .toString(),
        )
    }
}

internal data class WearCompletionFeedbackModel(
    val label: String,
    val isDestructive: Boolean,
)

internal data class WearRunControlModel(
    val primaryLabel: String,
    val primaryIcon: WearRunButtonIcon,
    val primaryIsResume: Boolean,
    val secondaryLabel: String,
    val secondaryIcon: WearRunButtonIcon,
    val secondaryIsDestructive: Boolean,
)

internal object WearRunControlModelBuilder {
    fun from(state: WearRunState): WearRunControlModel {
        val isPaused = state.phase == WearRunPhase.Paused
        return WearRunControlModel(
            primaryLabel = if (isPaused) "재개" else "일시정지",
            primaryIcon = if (isPaused) WearRunButtonIcon.Play else WearRunButtonIcon.Pause,
            primaryIsResume = isPaused,
            secondaryLabel = "중지",
            secondaryIcon = WearRunButtonIcon.Stop,
            secondaryIsDestructive = true,
        )
    }
}

internal object WearCompletionFeedbackModelBuilder {
    fun from(state: WearRunState): WearCompletionFeedbackModel {
        return when (state.feedbackType) {
            WearRunFeedbackType.Discarded -> WearCompletionFeedbackModel(
                label = "삭제 완료",
                isDestructive = true,
            )
            WearRunFeedbackType.Saved,
            null,
            -> WearCompletionFeedbackModel(
                label = "저장 완료",
                isDestructive = false,
            )
        }
    }
}

internal object WearReadyScreenModelBuilder {
    fun from(state: WearRunState): WearReadyScreenModel {
        val hasRecordRace = state.recordRaceConfig != null
        val recordRaceCount = state.recordRaceConfigs.size.takeIf { count -> count > 0 }
            ?: if (hasRecordRace) 1 else 0
        return WearReadyScreenModel(
            primaryLabel = if (hasRecordRace) "기록 레이스\n시작" else "시작",
            usesRecordRacePrimary = hasRecordRace,
            secondaryLabel = if (hasRecordRace) "일반 시작" else null,
            statusLabel = state.errorMessage ?: readyStatusMessage(state.statusMessage),
            isError = state.errorMessage != null,
            recordRaceLabel = state.recordRaceConfig?.sourceSummary,
            recordRaceCount = recordRaceCount,
        )
    }

    private fun readyStatusMessage(message: String?): String {
        return when (message) {
            "저장됨", "삭제됨", null -> "준비 완료"
            else -> message
        }
    }
}

internal data class WearReviewSummaryModel(
    val elapsed: String,
    val distance: String,
    val averagePace: String,
    val heartRate: String,
    val averageCadence: String,
    val calories: String,
    val speed: String,
    val recordRaceResult: String?,
    val pendingLabel: String?,
    val detailMetrics: List<WearReviewMetric>,
)

internal data class WearReviewMetric(
    val label: String,
    val value: String,
)

internal object WearReviewSummaryModelBuilder {
    fun from(state: WearRunState): WearReviewSummaryModel {
        val heartRate = WearRunFormatters.heartRate(state.heartRateBpm)
        val averageCadence = WearRunFormatters.cadence(state.averageCadenceSpm)
        val calories = WearRunFormatters.calories(state.caloriesKcal)
        val speed = WearRunFormatters.speed(state.speedMps)
        val pendingLabel = if (state.pendingDraftCount > 0) {
            "전송 대기 ${state.pendingDraftCount}개"
        } else {
            null
        }
        return WearReviewSummaryModel(
            elapsed = WearRunFormatters.elapsed(state.elapsedMs),
            distance = WearRunFormatters.distance(state.distanceM),
            averagePace = WearRunFormatters.pace(state.averagePaceSecPerKm),
            heartRate = heartRate,
            averageCadence = averageCadence,
            calories = calories,
            speed = speed,
            recordRaceResult = if (state.isRecordRaceRun && state.recordRaceFrame != null) {
                WearRunFormatters.recordRaceResult(state.recordRaceFrame)
            } else {
                null
            },
            pendingLabel = pendingLabel,
            detailMetrics = buildList {
                add(WearReviewMetric("칼로리", calories))
                add(WearReviewMetric("심박수", heartRate))
                add(WearReviewMetric("케이던스", averageCadence))
                add(WearReviewMetric("속도", speed))
                pendingLabel?.let { add(WearReviewMetric("동기화", it)) }
            },
        )
    }
}

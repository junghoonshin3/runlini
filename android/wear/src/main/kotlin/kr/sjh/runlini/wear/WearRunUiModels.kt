package kr.sjh.runlini.wear

internal enum class WearActiveRunPage { Core, Ghost, Details, Controls }

internal object WearActiveRunPageModel {
    fun pagesFor(state: WearRunState): List<WearActiveRunPage> {
        return buildList {
            add(WearActiveRunPage.Core)
            if (state.isGhostRun) {
                add(WearActiveRunPage.Ghost)
            }
            add(WearActiveRunPage.Details)
            add(WearActiveRunPage.Controls)
        }
    }
}

internal data class WearReadyScreenModel(
    val primaryLabel: String,
    val usesGhostPrimary: Boolean,
    val secondaryLabel: String?,
    val statusLabel: String,
    val isError: Boolean,
    val ghostLabel: String?,
    val pendingLabel: String?,
    val retryLabel: String?,
)

internal object WearReadyScreenModelBuilder {
    fun from(state: WearRunState): WearReadyScreenModel {
        val hasGhost = state.ghostConfig != null
        val pendingLabel = if (state.pendingDraftCount > 0) {
            "전송 대기 ${state.pendingDraftCount}개"
        } else {
            null
        }
        return WearReadyScreenModel(
            primaryLabel = if (hasGhost) "고스트\n시작" else "시작",
            usesGhostPrimary = hasGhost,
            secondaryLabel = if (hasGhost) "일반 시작" else null,
            statusLabel = state.errorMessage ?: state.statusMessage ?: "준비 완료",
            isError = state.errorMessage != null,
            ghostLabel = state.ghostConfig?.sourceSummary,
            pendingLabel = pendingLabel,
            retryLabel = pendingLabel?.let { "다시 보내기" },
        )
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
    val ghostResult: String?,
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
            ghostResult = if (state.isGhostRun && state.ghostFrame != null) {
                WearRunFormatters.ghostResult(state.ghostFrame)
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

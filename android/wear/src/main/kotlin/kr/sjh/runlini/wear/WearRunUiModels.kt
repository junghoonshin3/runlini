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
            primaryLabel = if (hasGhost) "GHOST\nSTART" else "START",
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
    val calories: String,
    val ghostResult: String?,
    val pendingLabel: String?,
)

internal object WearReviewSummaryModelBuilder {
    fun from(state: WearRunState): WearReviewSummaryModel {
        return WearReviewSummaryModel(
            elapsed = WearRunFormatters.elapsed(state.elapsedMs),
            distance = WearRunFormatters.distance(state.distanceM),
            averagePace = WearRunFormatters.pace(state.averagePaceSecPerKm),
            calories = WearRunFormatters.calories(state.caloriesKcal),
            ghostResult = if (state.isGhostRun) {
                WearRunFormatters.ghostResult(state.ghostFrame)
            } else {
                null
            },
            pendingLabel = if (state.pendingDraftCount > 0) {
                "전송 대기 ${state.pendingDraftCount}개"
            } else {
                null
            },
        )
    }
}

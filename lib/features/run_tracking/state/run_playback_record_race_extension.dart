part of 'run_playback_controller_providers.dart';

// 기록 레이스 완료 프롬프트 상태를 갱신하는 mixin
mixin RunPlaybackRecordRaceTracking on Notifier<RunPlaybackState> {
  void updateRecordRaceCompletion({
    required int candidateCount,
    RunSessionRecordRaceSummary? completedSummary,
  }) {
    if (completedSummary == null) {
      return;
    }
    if (!state.hasActiveSession || state.status != RunScreenStatus.running) {
      return;
    }
    if (state.recordRaceCompletionPromptDismissed ||
        state.recordRaceCompletionPromptPending) {
      return;
    }
    state = state.copyWith(
      recordRaceCompletionCandidateCount: candidateCount,
      recordRaceCompletionPromptPending: true,
      recordRaceCompletionSummary: completedSummary,
    );
  }

  void continueAfterRecordRaceCompletion() {
    if (!state.hasActiveSession) {
      return;
    }
    state = state.copyWith(
      recordRaceCompletionPromptPending: false,
      recordRaceCompletionPromptDismissed: true,
    );
  }
}

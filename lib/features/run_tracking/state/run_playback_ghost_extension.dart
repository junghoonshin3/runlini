part of 'run_playback_controller_providers.dart';

// 고스트런 완료 프롬프트 상태를 갱신하는 mixin
mixin RunPlaybackGhostTracking on Notifier<RunPlaybackState> {
  void updateGhostCompletion({
    required int candidateCount,
    RunSessionGhostSummary? completedSummary,
  }) {
    if (completedSummary == null) {
      return;
    }
    if (!state.hasActiveSession || state.status != RunScreenStatus.running) {
      return;
    }
    if (state.ghostCompletionPromptDismissed ||
        state.ghostCompletionPromptPending) {
      return;
    }
    state = state.copyWith(
      ghostCompletionCandidateCount: candidateCount,
      ghostCompletionPromptPending: true,
      ghostCompletionSummary: completedSummary,
    );
  }

  void continueAfterGhostCompletion() {
    if (!state.hasActiveSession) {
      return;
    }
    state = state.copyWith(
      ghostCompletionPromptPending: false,
      ghostCompletionPromptDismissed: true,
    );
  }
}

part of 'running_tab_screen.dart';

// 고스트런 완료 판정과 진단 로그를 담당하는 RunningTab 확장
extension _RunningTabGhostCompletion on _RunningTabScreenState {
  void _listenForGhostCompletion(BuildContext context) {
    ref.listen(ghostRaceFrameProvider, (previous, next) {
      final frame = next;
      if (frame == null) {
        return;
      }
      final playbackState = ref.read(runPlaybackControllerProvider);
      final selectedGhostSession = ref
          .read(runMapStaticStateProvider)
          .value
          ?.selectedGhostSession;
      final liveMetrics = ref.read(liveRunMetricsProvider);
      if (!playbackState.hasActiveSession ||
          selectedGhostSession == null ||
          liveMetrics == null) {
        return;
      }
      if (playbackState.status != RunScreenStatus.running) {
        _debugLogGhostCompletionBlocker(
          frame: frame,
          runnerDistanceM: liveMetrics.distanceKm * 1000,
          candidateCount: playbackState.ghostCompletionCandidateCount,
          screenStatus: playbackState.status,
          pauseReason: playbackState.pauseReason,
          reason: 'not-running',
        );
        return;
      }
      final decision = ref
          .read(ghostRaceCompletionDetectorProvider)
          .evaluate(
            frame: frame,
            runnerDistanceM: liveMetrics.distanceKm * 1000,
            previousCandidateCount: playbackState.ghostCompletionCandidateCount,
          );
      _debugLogGhostCompletionBlocker(
        frame: frame,
        runnerDistanceM: liveMetrics.distanceKm * 1000,
        candidateCount: decision.candidateCount,
        screenStatus: playbackState.status,
        pauseReason: playbackState.pauseReason,
        reason: decision.isComplete
            ? 'complete'
            : decision.isCandidate
            ? 'candidate'
            : 'blocked',
      );
      if (decision.isComplete &&
          !playbackState.ghostCompletionPromptPending &&
          !playbackState.ghostCompletionPromptDismissed) {
        unawaited(_safeGhostCompletionHaptic());
      }
      ref
          .read(runPlaybackControllerProvider.notifier)
          .updateGhostCompletion(
            candidateCount: decision.candidateCount,
            completedSummary: decision.isComplete
                ? runSessionGhostSummaryFromFrame(frame, selectedGhostSession)
                : null,
          );
    });
  }

  Future<void> _safeGhostCompletionHaptic() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (error, stackTrace) {
      debugPrint('Runlini ghost completion haptic failed: $error');
      debugPrint('$stackTrace');
    }
  }

  void _debugLogGhostCompletionBlocker({
    required GhostRaceFrame frame,
    required double runnerDistanceM,
    required int candidateCount,
    required RunScreenStatus screenStatus,
    required RunPauseReason? pauseReason,
    required String reason,
  }) {
    if (!kDebugMode && !kProfileMode) {
      return;
    }
    final total = frame.totalRouteDistanceM;
    final ratio = total > 0 ? runnerDistanceM / total : 0.0;
    final shouldLog =
        reason != 'blocked' ||
        frame.routeProgress >= 0.9 ||
        frame.distanceToFinishM <= 1000 ||
        frame.distanceToFinishPointM <= 100;
    if (!shouldLog) {
      return;
    }
    debugPrint(
      'Runlini ghost completion $reason '
      'runnerDistanceM=${runnerDistanceM.toStringAsFixed(1)} '
      'totalRouteDistanceM=${total.toStringAsFixed(1)} '
      'distanceRatio=${ratio.toStringAsFixed(2)} '
      'routeProgress=${frame.routeProgress.toStringAsFixed(3)} '
      'distanceToFinishM=${frame.distanceToFinishM.toStringAsFixed(1)} '
      'distanceToFinishPointM='
      '${frame.distanceToFinishPointM.toStringAsFixed(1)} '
      'distanceFromRouteM=${frame.distanceFromRouteM.toStringAsFixed(1)} '
      'candidateCount=$candidateCount '
      'screenStatus=${screenStatus.name} '
      'pauseReason=${pauseReason?.name ?? 'none'}',
    );
  }
}

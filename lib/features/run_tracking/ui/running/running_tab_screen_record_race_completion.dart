part of 'running_tab_screen.dart';

// 기록 레이스 완료 판정과 진단 로그를 담당하는 RunningTab 확장
extension _RunningTabRecordRaceCompletion on _RunningTabScreenState {
  void _handleRecordRaceCompletionFrame(RecordRaceFrame? frame) {
    if (frame == null) {
      _resetRecordRaceCompletionTracking();
      return;
    }
    final playbackState = ref.read(runPlaybackControllerProvider);
    _syncRecordRaceCompletionSession(playbackState.activeSessionId);
    final selectedRecordRaceSession = ref
        .read(runMapStaticStateProvider)
        .value
        ?.selectedRecordRaceSession;
    final liveMetrics = ref.read(liveRunMetricsProvider);
    if (!playbackState.hasActiveSession ||
        selectedRecordRaceSession == null ||
        liveMetrics == null) {
      _resetRecordRaceCompletionTracking(
        sessionId: playbackState.activeSessionId,
      );
      return;
    }
    final canEvaluateCompletion =
        playbackState.status == RunScreenStatus.running ||
        playbackState.isAutoPaused;
    if (!canEvaluateCompletion) {
      _recordRaceCompletionCandidateCount = 0;
      _debugLogRecordRaceCompletionBlocker(
        frame: frame,
        runnerDistanceM: liveMetrics.distanceKm * 1000,
        candidateCount: _recordRaceCompletionCandidateCount,
        screenStatus: playbackState.status,
        pauseReason: playbackState.pauseReason,
        reason: 'not-running',
      );
      return;
    }
    if (!frame.startConfirmed) {
      _recordRaceCompletionCandidateCount = 0;
      _debugLogRecordRaceCompletionBlocker(
        frame: frame,
        runnerDistanceM: liveMetrics.distanceKm * 1000,
        candidateCount: _recordRaceCompletionCandidateCount,
        screenStatus: playbackState.status,
        pauseReason: playbackState.pauseReason,
        reason: 'start-pending',
      );
      return;
    }

    final decision = ref
        .read(recordRaceCompletionDetectorProvider)
        .evaluate(
          frame: frame,
          runnerDistanceM: liveMetrics.distanceKm * 1000,
          previousCandidateCount: _recordRaceCompletionCandidateCount,
        );
    _recordRaceCompletionCandidateCount = decision.candidateCount;
    _debugLogRecordRaceCompletionBlocker(
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
    if (!decision.isComplete ||
        playbackState.recordRaceCompletionPromptPending ||
        playbackState.recordRaceCompletionPromptDismissed) {
      return;
    }

    final summary = runSessionRecordRaceSummaryFromFrame(
      frame,
      selectedRecordRaceSession,
    );
    if (summary == null) {
      return;
    }
    unawaited(_safeRecordRaceCompletionHaptic());
    _queueRecordRaceCompletionPrompt(
      candidateCount: decision.candidateCount,
      summary: summary,
    );
  }

  void _syncRecordRaceCompletionSession(String? sessionId) {
    if (_recordRaceCompletionSessionId == sessionId) {
      return;
    }
    _resetRecordRaceCompletionTracking(sessionId: sessionId);
  }

  void _resetRecordRaceCompletionTracking({String? sessionId}) {
    _recordRaceCompletionSessionId = sessionId;
    _recordRaceCompletionCandidateCount = 0;
    _recordRaceCompletionWriteQueued = false;
  }

  void _queueRecordRaceCompletionPrompt({
    required int candidateCount,
    required RunSessionRecordRaceSummary summary,
  }) {
    if (_recordRaceCompletionWriteQueued) {
      return;
    }
    _recordRaceCompletionWriteQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordRaceCompletionWriteQueued = false;
      if (!mounted) {
        return;
      }
      ref
          .read(runPlaybackControllerProvider.notifier)
          .updateRecordRaceCompletion(
            candidateCount: candidateCount,
            completedSummary: summary,
          );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _safeRecordRaceCompletionHaptic() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (error, stackTrace) {
      debugPrint('Runlini recordRace completion haptic failed: $error');
      debugPrint('$stackTrace');
    }
  }

  void _debugLogRecordRaceCompletionBlocker({
    required RecordRaceFrame frame,
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
      'Runlini recordRace completion $reason '
      'runnerDistanceM=${runnerDistanceM.toStringAsFixed(1)} '
      'totalRouteDistanceM=${total.toStringAsFixed(1)} '
      'distanceRatio=${ratio.toStringAsFixed(2)} '
      'routeProgress=${frame.routeProgress.toStringAsFixed(3)} '
      'distanceToFinishM=${frame.distanceToFinishM.toStringAsFixed(1)} '
      'distanceToFinishPointM='
      '${frame.distanceToFinishPointM.toStringAsFixed(1)} '
      'distanceFromRouteM=${frame.distanceFromRouteM.toStringAsFixed(1)} '
      'startConfirmed=${frame.startConfirmed} '
      'startCandidateCount=${frame.startCandidateCount} '
      'trackedDistanceAlongRouteM='
      '${frame.trackedDistanceAlongRouteM?.toStringAsFixed(1) ?? 'none'} '
      'projectionSource=${frame.projectionSource.name} '
      'candidateCount=$candidateCount '
      'screenStatus=${screenStatus.name} '
      'pauseReason=${pauseReason?.name ?? 'none'}',
    );
  }
}

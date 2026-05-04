part of 'run_playback_controller_providers.dart';

mixin RunPlaybackLiveSampleIngest on Notifier<RunPlaybackState> {
  DateTime? _lastCadenceEvidenceAt;

  void ingestLiveSample(LiveLocationSample sample) {
    if (!state.hasActiveSession ||
        state.startedAt == null ||
        (state.status == RunScreenStatus.paused &&
            state.pauseReason != RunPauseReason.auto)) {
      return;
    }

    final rawPoint = sample.toRunPoint(
      elapsedMs: sample.capturedAt.difference(state.startedAt!).inMilliseconds,
    );
    if (state.rawPoints.isNotEmpty &&
        _isDuplicateRawPoint(state.rawPoints.last, rawPoint)) {
      return;
    }
    final motionEvidence = ref.read(runMotionEvidenceProvider);
    final cadenceSpm = ref
        .read(runCadenceEstimatorProvider)
        .recentSpm(motionEvidence, at: sample.capturedAt);
    final recordedPoint = sample
        .toRunPoint(elapsedMs: state.elapsedAt(sample.capturedAt))
        .copyWith(cadenceSpm: cadenceSpm);
    final fusion = ref
        .read(runPlaybackSampleFusionProvider)
        .fuse(
          rawPoints: state.rawPoints,
          recordedPoints: state.recordedPoints,
          stationaryDriftLocked: state.stationaryDriftLocked,
          rawPoint: rawPoint,
          recordedPoint: recordedPoint,
          motionEvidence: motionEvidence,
          capturedAt: sample.capturedAt,
        );
    final autoPauseDecision = _autoPauseDecision(
      fusion,
      motionEvidence,
      sample.capturedAt,
    );
    if (autoPauseDecision == RunAutoPauseDecision.pause &&
        state.status == RunScreenStatus.running) {
      _applyAutoPause(fusion, motionEvidence, sample.capturedAt);
      return;
    }
    if (autoPauseDecision == RunAutoPauseDecision.resume &&
        state.isAutoPaused) {
      _applyAutoResume(fusion, motionEvidence, sample.capturedAt);
      return;
    }
    if (fusion.recordedPoints.length == state.recordedPoints.length &&
        fusion.rawPoints.length == state.rawPoints.length) {
      return;
    }
    state = state.copyWith(
      rawPoints: fusion.rawPoints,
      motionEvidence: motionEvidence,
      recordedPoints: fusion.recordedPoints,
      currentPointIndex: fusion.recordedPoints.length - 1,
      stationaryDriftLocked: fusion.stationaryDriftLocked,
    );
  }

  RunAutoPauseDecision _autoPauseDecision(
    RunPlaybackSampleFusionResult fusion,
    List<RunMotionEvidence> motionEvidence,
    DateTime capturedAt,
  ) {
    if (!state.autoPauseEnabled) return RunAutoPauseDecision.none;
    return ref
        .read(runAutoPauseDetectorProvider)
        .decide(
          rawPoints: fusion.rawPoints,
          acceptedPoints: fusion.acceptedRawPoints.isEmpty
              ? state.recordedPoints
              : fusion.acceptedRawPoints,
          isAutoPaused: state.isAutoPaused,
          motionEvidence: motionEvidence,
          capturedAt: capturedAt,
        );
  }

  void _applyAutoPause(
    RunPlaybackSampleFusionResult fusion,
    List<RunMotionEvidence> motionEvidence,
    DateTime capturedAt,
  ) {
    state = state.copyWith(
      status: RunScreenStatus.paused,
      rawPoints: fusion.rawPoints,
      motionEvidence: motionEvidence,
      recordedPoints: fusion.recordedPoints,
      currentPointIndex: _lastIndex(fusion),
      elapsedBeforePauseMs: state.elapsedAt(capturedAt),
      resumedAt: null,
      pauseReason: RunPauseReason.auto,
      stationaryDriftLocked: true,
    );
    _markCadenceEvidenceSeen(motionEvidence);
  }

  void _applyAutoResume(
    RunPlaybackSampleFusionResult fusion,
    List<RunMotionEvidence> motionEvidence,
    DateTime capturedAt,
  ) {
    state = state.copyWith(
      status: RunScreenStatus.running,
      rawPoints: fusion.rawPoints,
      motionEvidence: motionEvidence,
      recordedPoints: fusion.recordedPoints,
      currentPointIndex: _lastIndex(fusion),
      resumedAt: capturedAt,
      pauseReason: null,
      stationaryDriftLocked: false,
    );
    _markCadenceEvidenceSeen(motionEvidence);
  }

  int _lastIndex(RunPlaybackSampleFusionResult fusion) =>
      fusion.recordedPoints.isEmpty ? 0 : fusion.recordedPoints.length - 1;

  bool _isDuplicateRawPoint(RunPoint previous, RunPoint next) =>
      previous.timestampRelMs == next.timestampRelMs &&
      previous.latitude == next.latitude &&
      previous.longitude == next.longitude;

  void _accumulateCadenceSteps(List<RunMotionEvidence> evidence) {
    if (state.status != RunScreenStatus.running) {
      _markCadenceEvidenceSeen(evidence);
      return;
    }

    var stepDelta = 0;
    DateTime? latest;
    for (final item in evidence) {
      final last = _lastCadenceEvidenceAt;
      if (last != null && !item.timestamp.isAfter(last)) {
        continue;
      }
      latest = latest == null || item.timestamp.isAfter(latest)
          ? item.timestamp
          : latest;
      if (item.isAvailable) {
        stepDelta += item.stepDelta;
      }
    }
    if (latest != null) {
      _lastCadenceEvidenceAt = latest;
    }
    if (stepDelta <= 0) {
      return;
    }
    state = state.copyWith(
      cadenceStepCount: state.cadenceStepCount + stepDelta,
    );
  }

  void _markCadenceEvidenceSeen(List<RunMotionEvidence> evidence) {
    DateTime? latest;
    for (final item in evidence) {
      latest = latest == null || item.timestamp.isAfter(latest)
          ? item.timestamp
          : latest;
    }
    _lastCadenceEvidenceAt = latest;
  }

  void _resetCadenceTracking() {
    _lastCadenceEvidenceAt = null;
  }
}

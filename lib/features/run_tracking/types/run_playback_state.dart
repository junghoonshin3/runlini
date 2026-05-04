import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunPlaybackState {
  static const Object _unset = Object();

  const RunPlaybackState({
    required this.status,
    required this.currentPointIndex,
    required this.recordedPoints,
    required this.elapsedBeforePauseMs,
    this.startedAt,
    this.resumedAt,
    this.activeSessionId,
    this.pendingFinishedSession,
    this.intervalManualAdvanceCount = 0,
  });

  const RunPlaybackState.idle()
    : this(
        status: RunScreenStatus.idle,
        currentPointIndex: 0,
        recordedPoints: const <RunPoint>[],
        elapsedBeforePauseMs: 0,
      );

  final RunScreenStatus status;
  final int currentPointIndex;
  final List<RunPoint> recordedPoints;
  final int elapsedBeforePauseMs;
  final DateTime? startedAt;
  final DateTime? resumedAt;
  final String? activeSessionId;
  final RunSession? pendingFinishedSession;
  final int intervalManualAdvanceCount;

  bool get hasActiveSession =>
      status == RunScreenStatus.running || status == RunScreenStatus.paused;

  bool get isPaused => status == RunScreenStatus.paused;

  bool get isReviewing => status == RunScreenStatus.reviewing;

  int elapsedAt(DateTime now) {
    if (!hasActiveSession) {
      return 0;
    }

    if (status == RunScreenStatus.running && resumedAt != null) {
      final segmentMs = now.difference(resumedAt!).inMilliseconds;
      return elapsedBeforePauseMs + (segmentMs < 0 ? 0 : segmentMs);
    }

    return elapsedBeforePauseMs;
  }

  RunPlaybackState copyWith({
    RunScreenStatus? status,
    int? currentPointIndex,
    List<RunPoint>? recordedPoints,
    int? elapsedBeforePauseMs,
    Object? startedAt = _unset,
    Object? resumedAt = _unset,
    Object? activeSessionId = _unset,
    Object? pendingFinishedSession = _unset,
    int? intervalManualAdvanceCount,
  }) {
    return RunPlaybackState(
      status: status ?? this.status,
      currentPointIndex: currentPointIndex ?? this.currentPointIndex,
      recordedPoints: recordedPoints ?? this.recordedPoints,
      elapsedBeforePauseMs: elapsedBeforePauseMs ?? this.elapsedBeforePauseMs,
      startedAt: identical(startedAt, _unset)
          ? this.startedAt
          : startedAt as DateTime?,
      resumedAt: identical(resumedAt, _unset)
          ? this.resumedAt
          : resumedAt as DateTime?,
      activeSessionId: identical(activeSessionId, _unset)
          ? this.activeSessionId
          : activeSessionId as String?,
      pendingFinishedSession: identical(pendingFinishedSession, _unset)
          ? this.pendingFinishedSession
          : pendingFinishedSession as RunSession?,
      intervalManualAdvanceCount:
          intervalManualAdvanceCount ?? this.intervalManualAdvanceCount,
    );
  }
}

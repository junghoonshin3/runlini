import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';

Future<void> emitRecordRaceCompletionHaptic() async {
  try {
    await HapticFeedback.mediumImpact();
  } catch (error, stackTrace) {
    debugPrint('Runlini recordRace completion haptic failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

void debugRecordRaceCompletionDecision({
  required RunPlaybackState playbackState,
  required RecordRaceFrame frame,
  required double runnerDistanceM,
  required int candidateCount,
  required bool isComplete,
}) {
  if (!kDebugMode && !kProfileMode) {
    return;
  }
  _debugRecordRaceCompletion(
    tag: isComplete ? 'complete' : 'candidate',
    playbackState: playbackState,
    frame: frame,
    runnerDistanceM: runnerDistanceM,
    candidateCount: candidateCount,
  );
}

void debugRecordRaceCompletionBlockedDecision({
  required RunPlaybackState playbackState,
  required RecordRaceFrame frame,
  required double runnerDistanceM,
  required int candidateCount,
}) {
  if (!kDebugMode && !kProfileMode) {
    return;
  }
  if (!_isNearFinishForDiagnostics(frame)) {
    return;
  }
  _debugRecordRaceCompletion(
    tag: 'blocked',
    playbackState: playbackState,
    frame: frame,
    runnerDistanceM: runnerDistanceM,
    candidateCount: candidateCount,
  );
}

bool _isNearFinishForDiagnostics(RecordRaceFrame frame) {
  return frame.routeProgress >= 0.95 ||
      frame.distanceToFinishM <= 120 ||
      frame.distanceToFinishPointM <= 80;
}

void _debugRecordRaceCompletion({
  required String tag,
  required RunPlaybackState playbackState,
  required RecordRaceFrame frame,
  required double runnerDistanceM,
  required int candidateCount,
}) {
  final totalDistance = frame.totalRouteDistanceM;
  final distanceRatio = totalDistance.isFinite && totalDistance > 0
      ? runnerDistanceM / totalDistance
      : double.nan;
  debugPrint(
    'Runlini recordRace completion $tag: '
    'session=${playbackState.activeSessionId}, '
    'screenStatus=${playbackState.status.name}, '
    'pauseReason=${playbackState.pauseReason?.name}, '
    'status=${frame.status.name}, '
    'candidateCount=$candidateCount, '
    'runnerDistanceM=${runnerDistanceM.toStringAsFixed(1)}, '
    'totalRouteDistanceM=${totalDistance.toStringAsFixed(1)}, '
    'distanceRatio=${distanceRatio.toStringAsFixed(3)}, '
    'routeProgress=${frame.routeProgress.toStringAsFixed(3)}, '
    'distanceToFinishM=${frame.distanceToFinishM.toStringAsFixed(1)}, '
    'distanceToFinishPointM=${frame.distanceToFinishPointM.toStringAsFixed(1)}, '
    'distanceFromRouteM=${frame.distanceFromRouteM.toStringAsFixed(1)}',
  );
}

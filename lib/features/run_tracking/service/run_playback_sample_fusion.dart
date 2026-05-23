import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/service/run_motion_evidence_gate.dart';
import 'package:runlini/features/run_tracking/service/run_point_sanitizer.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class RunPlaybackSampleFusion {
  const RunPlaybackSampleFusion({
    required this.sanitizer,
    required this.motionGate,
  });

  final RunPointSanitizer sanitizer;
  final RunMotionEvidenceGate motionGate;

  RunPlaybackSampleFusionResult fuse({
    required List<RunPoint> rawPoints,
    required List<RunPoint> recordedPoints,
    required bool stationaryDriftLocked,
    required RunPoint rawPoint,
    required RunPoint recordedPoint,
    required List<RunMotionEvidence> motionEvidence,
    required DateTime capturedAt,
  }) {
    final nextRawPoints = <RunPoint>[...rawPoints, rawPoint];
    final acceptedRawPoints = sanitizer.filter(nextRawPoints);
    var nextRecordedPoints = acceptedRawPoints.length > recordedPoints.length
        ? <RunPoint>[...recordedPoints, recordedPoint]
        : recordedPoints;
    var nextLocked = stationaryDriftLocked;
    final motionAllowsMovement = motionGate.allowsMovementAt(
      motionEvidence,
      at: capturedAt,
    );
    if (nextLocked) {
      final movementConfirmed =
          sanitizer.isMovementConfirmed(
            recentRawPoints: nextRawPoints,
            anchor: recordedPoints.isEmpty ? null : recordedPoints.last,
          ) &&
          motionAllowsMovement;
      if (!movementConfirmed) {
        nextRecordedPoints = recordedPoints;
      }
      nextLocked = !movementConfirmed;
    } else if (sanitizer.hasStationaryWindow(nextRawPoints)) {
      nextRecordedPoints = recordedPoints;
      nextLocked = true;
    }
    return RunPlaybackSampleFusionResult(
      rawPoints: nextRawPoints,
      acceptedRawPoints: acceptedRawPoints,
      recordedPoints: nextRecordedPoints,
      stationaryDriftLocked: nextLocked,
    );
  }
}

class RunPlaybackSampleFusionResult {
  const RunPlaybackSampleFusionResult({
    required this.rawPoints,
    required this.acceptedRawPoints,
    required this.recordedPoints,
    required this.stationaryDriftLocked,
  });

  final List<RunPoint> rawPoints;
  final List<RunPoint> acceptedRawPoints;
  final List<RunPoint> recordedPoints;
  final bool stationaryDriftLocked;

  RunPlaybackSampleFusionResult copyWith({
    List<RunPoint>? rawPoints,
    List<RunPoint>? acceptedRawPoints,
    List<RunPoint>? recordedPoints,
    bool? stationaryDriftLocked,
  }) {
    return RunPlaybackSampleFusionResult(
      rawPoints: rawPoints ?? this.rawPoints,
      acceptedRawPoints: acceptedRawPoints ?? this.acceptedRawPoints,
      recordedPoints: recordedPoints ?? this.recordedPoints,
      stationaryDriftLocked:
          stationaryDriftLocked ?? this.stationaryDriftLocked,
    );
  }
}

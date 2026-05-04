import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/service/run_motion_evidence_gate.dart';
import 'package:runlini/features/run_tracking/service/run_point_sanitizer.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

enum RunAutoPauseDecision { none, pause, resume }

class RunAutoPauseDetector {
  const RunAutoPauseDetector({
    this.sanitizer = const RunPointSanitizer(),
    this.motionGate = const RunMotionEvidenceGate(),
  });

  final RunPointSanitizer sanitizer;
  final RunMotionEvidenceGate motionGate;

  RunAutoPauseDecision decide({
    required List<RunPoint> rawPoints,
    required List<RunPoint> acceptedPoints,
    required bool isAutoPaused,
    required List<RunMotionEvidence> motionEvidence,
    required DateTime capturedAt,
  }) {
    if (rawPoints.isEmpty || acceptedPoints.isEmpty) {
      return RunAutoPauseDecision.none;
    }
    if (isAutoPaused) {
      return sanitizer.isMovementConfirmed(
                recentRawPoints: rawPoints,
                anchor: acceptedPoints.last,
              ) &&
              motionGate.allowsMovementAt(motionEvidence, at: capturedAt)
          ? RunAutoPauseDecision.resume
          : RunAutoPauseDecision.none;
    }
    return sanitizer.hasStationaryWindow(rawPoints) &&
            motionGate.shouldPauseForStationary(motionEvidence, at: capturedAt)
        ? RunAutoPauseDecision.pause
        : RunAutoPauseDecision.none;
  }
}

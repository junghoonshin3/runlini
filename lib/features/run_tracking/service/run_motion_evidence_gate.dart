import 'package:runlini/core/motion/run_motion_evidence_client.dart';

class RunMotionEvidenceGate {
  const RunMotionEvidenceGate({
    this.recentWindow = const Duration(seconds: 4),
    this.requiredStepDelta = 2,
    this.minCadenceSpm = 40,
  });

  final Duration recentWindow;
  final int requiredStepDelta;
  final double minCadenceSpm;

  bool shouldUseMotion(List<RunMotionEvidence> evidence) {
    if (evidence.isEmpty) {
      return false;
    }
    return evidence.last.sourceAvailability ==
        RunMotionEvidenceSourceAvailability.available;
  }

  bool hasRecentMotion(
    List<RunMotionEvidence> evidence, {
    required DateTime at,
  }) {
    if (!shouldUseMotion(evidence)) {
      return false;
    }
    var stepDelta = 0;
    for (final item in evidence) {
      if (!item.isAvailable) {
        continue;
      }
      final delta = at.difference(item.timestamp);
      if (delta < -const Duration(seconds: 1) || delta > recentWindow) {
        continue;
      }
      stepDelta += item.stepDelta;
      final cadence = item.cadenceSpm;
      if (cadence != null && cadence >= minCadenceSpm) {
        return true;
      }
    }
    return stepDelta >= requiredStepDelta;
  }

  bool allowsMovementAt(
    List<RunMotionEvidence> evidence, {
    required DateTime at,
  }) {
    if (!shouldUseMotion(evidence)) {
      return true;
    }
    return hasRecentMotion(evidence, at: at);
  }

  bool shouldPauseForStationary(
    List<RunMotionEvidence> evidence, {
    required DateTime at,
  }) {
    if (!shouldUseMotion(evidence)) {
      return true;
    }
    return !hasRecentMotion(evidence, at: at);
  }
}

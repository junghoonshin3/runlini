import 'package:runlini/core/motion/run_motion_evidence_client.dart';

class RunCadenceEstimator {
  const RunCadenceEstimator({
    this.recentWindow = const Duration(seconds: 20),
    this.minimumStepWindow = const Duration(seconds: 5),
    this.maxCadenceSpm = 260,
  });

  final Duration recentWindow;
  final Duration minimumStepWindow;
  final double maxCadenceSpm;

  double? averageSpm({required int stepCount, required int durationMs}) {
    if (stepCount <= 0 || durationMs <= 0) {
      return null;
    }
    final cadence = stepCount / (durationMs / Duration.millisecondsPerMinute);
    return _validCadence(cadence) ? cadence : null;
  }

  double? recentSpm(List<RunMotionEvidence> evidence, {required DateTime at}) {
    double? latestSensorCadence;
    for (final item in evidence) {
      if (_isRecent(item, at) && _validCadence(item.cadenceSpm)) {
        latestSensorCadence = item.cadenceSpm;
      }
    }
    if (latestSensorCadence != null) {
      return latestSensorCadence;
    }

    final stepEvidence = evidence
        .where((item) => _isRecent(item, at) && item.isAvailable)
        .toList(growable: false);
    final stepCount = stepEvidence.fold<int>(
      0,
      (total, item) => total + item.stepDelta,
    );
    if (stepCount <= 0 || stepEvidence.isEmpty) {
      return null;
    }

    final span = at.difference(stepEvidence.first.timestamp);
    if (span < minimumStepWindow) {
      return null;
    }
    return averageSpm(stepCount: stepCount, durationMs: span.inMilliseconds);
  }

  bool _isRecent(RunMotionEvidence evidence, DateTime at) {
    final age = at.difference(evidence.timestamp);
    return age >= Duration.zero && age <= recentWindow;
  }

  bool _validCadence(double? cadenceSpm) {
    return cadenceSpm != null &&
        cadenceSpm.isFinite &&
        cadenceSpm > 0 &&
        cadenceSpm <= maxCadenceSpm;
  }
}

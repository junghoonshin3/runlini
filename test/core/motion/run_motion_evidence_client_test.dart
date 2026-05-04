import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';

void main() {
  test('maps available platform step evidence', () {
    final evidence = RunMotionEvidence.fromPlatformEvent(const {
      'availability': 'available',
      'stepDelta': 2,
      'timestampEpochMs': 1770000000000,
    });

    expect(
      evidence.sourceAvailability,
      RunMotionEvidenceSourceAvailability.available,
    );
    expect(evidence.stepDelta, 2);
    expect(evidence.timestamp.millisecondsSinceEpoch, 1770000000000);
  });

  test('maps permission denied and clamps invalid step deltas', () {
    final evidence = RunMotionEvidence.fromPlatformEvent(const {
      'availability': 'permissionDenied',
      'stepDelta': -3,
      'timestampEpochMs': 1770000000000,
    });

    expect(
      evidence.sourceAvailability,
      RunMotionEvidenceSourceAvailability.permissionDenied,
    );
    expect(evidence.stepDelta, 0);
  });
}

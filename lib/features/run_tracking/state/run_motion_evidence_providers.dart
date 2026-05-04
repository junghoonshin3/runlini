import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/motion/run_motion_evidence_client.dart';
import 'package:runlini/features/run_tracking/service/run_motion_evidence_gate.dart';

final runMotionEvidenceGateProvider = Provider<RunMotionEvidenceGate>(
  (Ref ref) => const RunMotionEvidenceGate(),
);

final runMotionEvidenceProvider =
    NotifierProvider<RunMotionEvidenceController, List<RunMotionEvidence>>(
      RunMotionEvidenceController.new,
    );

class RunMotionEvidenceController extends Notifier<List<RunMotionEvidence>> {
  StreamSubscription<RunMotionEvidence>? _subscription;
  bool _trackingEnabled = false;

  @override
  List<RunMotionEvidence> build() {
    ref.onDispose(() {
      unawaited(_stop());
    });
    return const <RunMotionEvidence>[];
  }

  void setTrackingEnabled(bool enabled) {
    if (_trackingEnabled == enabled) {
      return;
    }
    _trackingEnabled = enabled;
    if (enabled) {
      _start();
    } else {
      unawaited(_stop());
      state = const <RunMotionEvidence>[];
    }
  }

  void ingestEvidence(RunMotionEvidence evidence) {
    state = _pruned(<RunMotionEvidence>[
      ...state,
      evidence,
    ], evidence.timestamp);
  }

  void _start() {
    unawaited(_stop());
    state = const <RunMotionEvidence>[];
    _subscription = ref
        .read(runMotionEvidenceClientProvider)
        .watchMotionEvidence()
        .listen(
          ingestEvidence,
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('Runlini motion evidence stream failed: $error');
            ingestEvidence(RunMotionEvidence.unavailable(DateTime.now()));
          },
        );
  }

  Future<void> _stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  List<RunMotionEvidence> _pruned(
    List<RunMotionEvidence> evidence,
    DateTime reference,
  ) {
    return evidence
        .where(
          (item) =>
              reference.difference(item.timestamp) <=
              const Duration(seconds: 20),
        )
        .toList(growable: false);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RunMotionEvidenceSourceAvailability {
  available,
  unavailable,
  permissionDenied,
}

@immutable
class RunMotionEvidence {
  const RunMotionEvidence({
    required this.timestamp,
    required this.stepDelta,
    required this.sourceAvailability,
    this.cadenceSpm,
  });

  final DateTime timestamp;
  final int stepDelta;
  final double? cadenceSpm;
  final RunMotionEvidenceSourceAvailability sourceAvailability;

  bool get isAvailable =>
      sourceAvailability == RunMotionEvidenceSourceAvailability.available;

  static RunMotionEvidence unavailable(DateTime timestamp) {
    return RunMotionEvidence(
      timestamp: timestamp,
      stepDelta: 0,
      sourceAvailability: RunMotionEvidenceSourceAvailability.unavailable,
    );
  }

  static RunMotionEvidence fromPlatformEvent(Object? event) {
    final map = Map<Object?, Object?>.from(event as Map<Object?, Object?>);
    final timestampMs = (map['timestampEpochMs'] as num?)?.round();
    final availability = switch (map['availability'] as String?) {
      'available' => RunMotionEvidenceSourceAvailability.available,
      'permissionDenied' =>
        RunMotionEvidenceSourceAvailability.permissionDenied,
      _ => RunMotionEvidenceSourceAvailability.unavailable,
    };
    return RunMotionEvidence(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        timestampMs ?? DateTime.now().millisecondsSinceEpoch,
      ),
      stepDelta: ((map['stepDelta'] as num?)?.round() ?? 0).clamp(0, 100),
      cadenceSpm: (map['cadenceSpm'] as num?)?.toDouble(),
      sourceAvailability: availability,
    );
  }
}

abstract class RunMotionEvidenceClient {
  Stream<RunMotionEvidence> watchMotionEvidence();
}

class PlatformRunMotionEvidenceClient implements RunMotionEvidenceClient {
  const PlatformRunMotionEvidenceClient({
    EventChannel channel = const EventChannel('runlini/motion_evidence'),
  }) : _channel = channel;

  final EventChannel _channel;

  @override
  Stream<RunMotionEvidence> watchMotionEvidence() {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return Stream<RunMotionEvidence>.value(
        RunMotionEvidence.unavailable(DateTime.now()),
      );
    }
    var hasFlutterBinding = true;
    assert(() {
      hasFlutterBinding = BindingBase.debugBindingType() != null;
      return true;
    }());
    if (!hasFlutterBinding) {
      return Stream<RunMotionEvidence>.value(
        RunMotionEvidence.unavailable(DateTime.now()),
      );
    }

    return Stream<RunMotionEvidence>.multi((controller) {
      StreamSubscription<dynamic>? subscription;
      try {
        subscription = _channel.receiveBroadcastStream().listen(
          (Object? event) {
            controller.add(RunMotionEvidence.fromPlatformEvent(event));
          },
          onError: (_) {
            controller.add(RunMotionEvidence.unavailable(DateTime.now()));
          },
          onDone: controller.close,
        );
      } catch (_) {
        controller.add(RunMotionEvidence.unavailable(DateTime.now()));
        controller.close();
      }
      controller.onCancel = () => subscription?.cancel();
    });
  }
}

final runMotionEvidenceClientProvider = Provider<RunMotionEvidenceClient>(
  (Ref ref) => const PlatformRunMotionEvidenceClient(),
);

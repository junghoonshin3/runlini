import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/service/pace_colored_route_segment_builder.dart';
import 'package:runlini/features/run_tracking/service/run_auto_pause_detector.dart';
import 'package:runlini/features/run_tracking/service/run_cadence_estimator.dart';
import 'package:runlini/features/run_tracking/service/run_playback_sample_fusion.dart';
import 'package:runlini/features/run_tracking/service/run_point_sanitizer.dart';
import 'package:runlini/features/run_tracking/state/run_motion_evidence_providers.dart';

enum RunTrackingToggleResult { started, stopped, unavailable }

typedef RunPlaybackClock = DateTime Function();

final startupCurrentLocationTimeoutProvider = Provider<Duration>(
  (Ref ref) => const Duration(seconds: 2),
);

final runPlaybackClockProvider = Provider<RunPlaybackClock>(
  (Ref ref) => DateTime.now,
);

final runPointSanitizerProvider = Provider<RunPointSanitizer>(
  (Ref ref) => const RunPointSanitizer(),
);

final runAutoPauseDetectorProvider = Provider<RunAutoPauseDetector>(
  (Ref ref) => RunAutoPauseDetector(
    sanitizer: ref.watch(runPointSanitizerProvider),
    motionGate: ref.watch(runMotionEvidenceGateProvider),
  ),
);

final runCadenceEstimatorProvider = Provider<RunCadenceEstimator>(
  (Ref ref) => const RunCadenceEstimator(),
);

final runPlaybackSampleFusionProvider = Provider<RunPlaybackSampleFusion>(
  (Ref ref) => RunPlaybackSampleFusion(
    sanitizer: ref.watch(runPointSanitizerProvider),
    motionGate: ref.watch(runMotionEvidenceGateProvider),
  ),
);

final paceColoredRouteSegmentBuilderProvider =
    Provider<PaceColoredRouteSegmentBuilder>(
      (Ref ref) => const PaceColoredRouteSegmentBuilder(),
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/service/pace_colored_route_segment_builder.dart';
import 'package:runlini/features/run_tracking/service/run_point_sanitizer.dart';

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

final paceColoredRouteSegmentBuilderProvider =
    Provider<PaceColoredRouteSegmentBuilder>(
      (Ref ref) => const PaceColoredRouteSegmentBuilder(),
    );

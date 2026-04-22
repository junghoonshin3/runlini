import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/service/live_run_metrics_calculator.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';

final liveRunMetricsCalculatorProvider = Provider<LiveRunMetricsCalculator>(
  (Ref ref) => const LiveRunMetricsCalculator(),
);

final liveRunMetricsTickerIntervalProvider = Provider<Duration>(
  (Ref ref) => const Duration(seconds: 1),
);

final liveRunMetricsTickerProvider = StreamProvider<int>((Ref ref) async* {
  yield 0;
  var tick = 1;
  yield* Stream<int>.periodic(
    ref.watch(liveRunMetricsTickerIntervalProvider),
    (_) => tick++,
  );
});

final liveRunMetricsProvider = Provider<LiveRunMetrics?>((Ref ref) {
  final playbackState = ref.watch(runPlaybackControllerProvider);
  if (!playbackState.hasActiveSession || playbackState.startedAt == null) {
    return null;
  }

  ref.watch(liveRunMetricsTickerProvider);
  return ref
      .watch(liveRunMetricsCalculatorProvider)
      .calculate(
        playbackState: playbackState,
        now: ref.watch(runPlaybackClockProvider)(),
      );
});

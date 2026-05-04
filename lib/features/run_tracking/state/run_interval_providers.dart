import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_controller_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';

final runIntervalWorkoutCalculatorProvider =
    Provider<RunIntervalWorkoutCalculator>(
      (Ref ref) => const RunIntervalWorkoutCalculator(),
    );

final runIntervalFrameProvider = Provider<RunIntervalFrame?>((Ref ref) {
  final settings = ref.watch(runSettingsControllerProvider).value;
  final workout = settings?.intervalWorkout;
  if (workout == null || !workout.enabled) {
    return null;
  }
  final metrics = ref.watch(liveRunMetricsProvider);
  if (metrics == null) {
    return null;
  }
  final playback = ref.watch(runPlaybackControllerProvider);
  return ref
      .watch(runIntervalWorkoutCalculatorProvider)
      .calculate(
        workout: workout,
        elapsedMs: metrics.elapsedMs,
        distanceM: metrics.distanceKm * 1000,
        manualAdvanceCount: playback.intervalManualAdvanceCount,
      );
});

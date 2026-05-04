import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_start_countdown_state.dart';

final runStartCountdownStepDurationProvider = Provider<Duration>(
  (Ref ref) => const Duration(seconds: 1),
);

final runStartCountdownSecondsProvider = Provider<int>((Ref ref) {
  return defaultRunCountdownSeconds;
});

class RunStartCountdownController extends Notifier<RunStartCountdownState> {
  @override
  RunStartCountdownState build() => const RunStartCountdownState.inactive();

  Future<RunTrackingToggleResult?> startAfterCountdown({
    required Future<RunTrackingToggleResult> Function() onStart,
  }) async {
    if (state.isActive) {
      return null;
    }

    final stepDuration = ref.read(runStartCountdownStepDurationProvider);
    final countdownSeconds = ref.read(runStartCountdownSecondsProvider);
    for (
      var remainingSeconds = countdownSeconds;
      remainingSeconds >= 1;
      remainingSeconds -= 1
    ) {
      state = RunStartCountdownState.active(remainingSeconds: remainingSeconds);
      await Future<void>.delayed(stepDuration);
    }

    try {
      return await onStart();
    } finally {
      state = const RunStartCountdownState.inactive();
    }
  }
}

final runStartCountdownControllerProvider =
    NotifierProvider<RunStartCountdownController, RunStartCountdownState>(
      RunStartCountdownController.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/types/run_start_countdown_state.dart';

void main() {
  test('ignores re-entry while a countdown is already active', () async {
    final container = ProviderContainer(
      overrides: [
        runStartCountdownStepDurationProvider.overrideWithValue(
          const Duration(milliseconds: 1),
        ),
      ],
    );
    addTearDown(container.dispose);

    var callbackCount = 0;
    final firstRun = container
        .read(runStartCountdownControllerProvider.notifier)
        .startAfterCountdown(
          onStart: () async {
            callbackCount += 1;
            return RunTrackingToggleResult.started;
          },
        );

    expect(
      container.read(runStartCountdownControllerProvider).remainingSeconds,
      3,
    );

    final secondRun = await container
        .read(runStartCountdownControllerProvider.notifier)
        .startAfterCountdown(
          onStart: () async {
            callbackCount += 1;
            return RunTrackingToggleResult.started;
          },
        );

    expect(secondRun, isNull);
    expect(await firstRun, RunTrackingToggleResult.started);
    expect(callbackCount, 1);
    expect(
      container.read(runStartCountdownControllerProvider),
      const RunStartCountdownState.inactive(),
    );
  });

  test('resets to inactive after an unavailable start result', () async {
    final container = ProviderContainer(
      overrides: [
        runStartCountdownStepDurationProvider.overrideWithValue(
          const Duration(milliseconds: 1),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(runStartCountdownControllerProvider.notifier)
        .startAfterCountdown(
          onStart: () async => RunTrackingToggleResult.unavailable,
        );

    expect(result, RunTrackingToggleResult.unavailable);
    expect(
      container.read(runStartCountdownControllerProvider),
      const RunStartCountdownState.inactive(),
    );
  });

  test('uses the configured countdown length', () async {
    final container = ProviderContainer(
      overrides: [
        runStartCountdownSecondsProvider.overrideWithValue(5),
        runStartCountdownStepDurationProvider.overrideWithValue(
          const Duration(milliseconds: 1),
        ),
      ],
    );
    addTearDown(container.dispose);
    final seenSeconds = <int>[];
    container.listen(runStartCountdownControllerProvider, (previous, next) {
      final remainingSeconds = next.remainingSeconds;
      if (remainingSeconds != null) {
        seenSeconds.add(remainingSeconds);
      }
    });

    final result = await container
        .read(runStartCountdownControllerProvider.notifier)
        .startAfterCountdown(
          onStart: () async => RunTrackingToggleResult.started,
        );

    expect(result, RunTrackingToggleResult.started);
    expect(seenSeconds, <int>[5, 4, 3, 2, 1]);
  });
}

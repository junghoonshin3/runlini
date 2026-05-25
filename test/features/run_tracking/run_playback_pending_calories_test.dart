// 완료 리뷰 중 몸무게 저장 칼로리 갱신을 검증한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test('body weight saved during review updates pending calories', () async {
    final seedSample = playbackSample(
      latitude: 37.0,
      longitude: 127.0,
      capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
    );
    final acceptedSample = playbackSample(
      latitude: 37.0001,
      longitude: 127.0001,
      capturedAt: DateTime(2026, 4, 20, 6, 0, 5),
    );
    final streamClient = TrackingLocationStreamClient();
    final sessionRepository = TestRunSessionRepository();
    final settingsRepository = TestRunSettingsRepository();
    var now = DateTime(2026, 4, 20, 6, 0, 3);
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(
          TestDeviceLocationClient(),
        ),
        locationStreamClientProvider.overrideWithValue(streamClient),
        runSessionRepositoryProvider.overrideWithValue(sessionRepository),
        runSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        runPlaybackClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    await container.read(runSettingsControllerProvider.future);
    await startVisibleLiveTracking(container);
    await streamClient.emit(seedSample);
    await container.read(runPlaybackControllerProvider.notifier).start();
    await streamClient.emit(acceptedSample);
    now = DateTime(2026, 4, 20, 6, 0, 8);
    await container.read(runPlaybackControllerProvider.notifier).stop();

    expect(
      container
          .read(runPlaybackControllerProvider)
          .pendingFinishedSession!
          .caloriesKcal,
      isNull,
    );

    await container
        .read(runSettingsControllerProvider.notifier)
        .setBodyWeightKg(70);
    container
        .read(runPlaybackControllerProvider.notifier)
        .applyBodyWeightToPendingFinishedRun(70);

    final pendingSession = container
        .read(runPlaybackControllerProvider)
        .pendingFinishedSession!;
    expect(pendingSession.caloriesKcal, isNotNull);

    await container
        .read(runPlaybackControllerProvider.notifier)
        .saveFinishedRun();

    expect(settingsRepository.settings.bodyWeightKg, 70);
    expect(sessionRepository.savedSessions.single.caloriesKcal, isNotNull);
  });
}

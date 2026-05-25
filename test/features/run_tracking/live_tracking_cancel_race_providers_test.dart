// 라이브 트래킹 취소 경쟁 상태 회귀 테스트를 분리한다.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test(
    'rapid manual pause and resume leaves live tracking in workout mode',
    () async {
      final startedAt = DateTime(2026, 4, 20, 6, 0, 0);
      var now = startedAt;
      final streamClient = _DelayedCancelLocationStreamClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(
            TestDeviceLocationClient(),
          ),
          locationStreamClientProvider.overrideWithValue(streamClient),
          runPlaybackClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(() async {
        streamClient.completePendingCancel();
        await streamClient.close();
        container.dispose();
      });

      await startVisibleLiveTracking(container);
      await streamClient.emit(
        playbackSample(latitude: 37.0, longitude: 127.0, capturedAt: startedAt),
      );
      await container.read(runPlaybackControllerProvider.notifier).start();
      await settleAsync();
      expect(streamClient.lastWatchMode, LocationTrackingMode.workout);

      streamClient.delayNextCancel();
      now = startedAt.add(const Duration(seconds: 5));
      await container.read(runPlaybackControllerProvider.notifier).pause();
      for (
        var index = 0;
        index < 5 && !streamClient.hasPendingCancel;
        index++
      ) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(streamClient.hasPendingCancel, isTrue);

      now = startedAt.add(const Duration(seconds: 6));
      await container.read(runPlaybackControllerProvider.notifier).resume();
      streamClient.completePendingCancel();
      await settleAsync();
      await settleAsync();

      expect(
        container.read(runPlaybackControllerProvider).status,
        RunScreenStatus.running,
      );
      expect(streamClient.activeSubscriptions, 1);
      expect(streamClient.lastWatchMode, LocationTrackingMode.workout);
    },
  );
}

class _DelayedCancelLocationStreamClient implements LocationStreamClient {
  _DelayedCancelLocationStreamClient() {
    _controller = StreamController<LiveLocationSample>.broadcast(
      onListen: () => _activeSubscriptions += 1,
      onCancel: _handleCancel,
    );
  }

  late final StreamController<LiveLocationSample> _controller;
  int _activeSubscriptions = 0;
  bool _delayNextCancel = false;
  Completer<void>? _pendingCancel;
  final List<LocationTrackingMode> watchModes = <LocationTrackingMode>[];

  int get activeSubscriptions => _activeSubscriptions;

  bool get hasPendingCancel => _pendingCancel != null;

  LocationTrackingMode? get lastWatchMode =>
      watchModes.isEmpty ? null : watchModes.last;

  void delayNextCancel() {
    _delayNextCancel = true;
  }

  void completePendingCancel() {
    final pendingCancel = _pendingCancel;
    _pendingCancel = null;
    pendingCancel?.complete();
  }

  Future<void> _handleCancel() async {
    _activeSubscriptions -= 1;
    if (!_delayNextCancel || _pendingCancel != null) {
      return;
    }
    _delayNextCancel = false;
    _pendingCancel = Completer<void>();
    await _pendingCancel!.future;
  }

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async => null;

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async => null;

  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
    LocationTrackingConfig? config,
  }) {
    watchModes.add(mode);
    return _controller.stream;
  }

  Future<void> emit(LiveLocationSample sample) async {
    _controller.add(sample);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await _controller.close();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/run_tracking/state/run_playback_controller_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_core_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';

class LiveLocationController extends Notifier<LiveLocationSample?> {
  StreamSubscription<LiveLocationSample>? _locationSubscription;
  LiveLocationSample? _latestSample;
  LocationTrackingMode? _activeTrackingMode;
  bool _workoutTrackingEnabled = false;

  @override
  LiveLocationSample? build() {
    ref.listen<AppTab>(appTabProvider, (AppTab? previous, AppTab next) {
      if (previous != next) {
        unawaited(_syncTracking());
      }
    });
    ref.onDispose(() {
      unawaited(_stopTracking());
    });
    return _latestSample;
  }

  Future<LiveLocationSample?> bootstrapInitialLocation() async {
    if (state != null) {
      return state;
    }

    final deviceLocationClient = ref.read(deviceLocationClientProvider);
    try {
      final lastKnownSample = await deviceLocationClient.fetchLastKnownSample();
      if (lastKnownSample != null) {
        _setSample(lastKnownSample);
        return state;
      }
    } catch (error) {
      debugPrint('Runlini last-known location bootstrap failed: $error');
    }

    try {
      final currentSample = await deviceLocationClient
          .fetchCurrentSample()
          .timeout(ref.read(startupCurrentLocationTimeoutProvider));
      if (currentSample != null) {
        _setSample(currentSample);
      }
    } on TimeoutException {
      return state;
    } catch (error) {
      debugPrint('Runlini current location bootstrap failed: $error');
    }

    return state;
  }

  Future<void> syncTracking() {
    return _syncTracking();
  }

  Future<LiveLocationSample?> prepareQuickRecenterTarget() async {
    if (state != null) {
      return state;
    }

    try {
      final lastKnownSample = await ref
          .read(deviceLocationClientProvider)
          .fetchLastKnownSample();
      if (lastKnownSample != null) {
        _setSample(lastKnownSample);
      }
    } catch (error) {
      debugPrint('Runlini quick recenter target failed: $error');
    }

    return state;
  }

  Future<LiveLocationSample?> refresh() async {
    try {
      final currentSample = await ref
          .read(deviceLocationClientProvider)
          .fetchCurrentSample();
      if (currentSample != null) {
        _setSample(currentSample);
      }
    } catch (error) {
      debugPrint('Runlini current location refresh failed: $error');
    }
    return state;
  }

  void setWorkoutTrackingEnabled(bool enabled) {
    if (_workoutTrackingEnabled == enabled) {
      return;
    }

    _workoutTrackingEnabled = enabled;
    unawaited(_syncTracking());
  }

  Future<void> _syncTracking() async {
    try {
      if (!ref.mounted) {
        return;
      }
      final nextMode = _desiredTrackingMode();
      if (nextMode != null) {
        if (_locationSubscription != null && _activeTrackingMode == nextMode) {
          return;
        }
        await _stopTracking();
        if (!ref.mounted) {
          return;
        }
        _activeTrackingMode = nextMode;
        _locationSubscription = ref
            .read(locationStreamClientProvider)
            .watchLocationSamples(mode: nextMode)
            .listen(
              _ingestSample,
              onError: (Object error, StackTrace stackTrace) {
                _handleTrackingError();
              },
            );
        return;
      }

      await _stopTracking();
    } catch (error) {
      debugPrint('Runlini live location sync failed: $error');
      await _stopTracking();
    }
  }

  LocationTrackingMode? _desiredTrackingMode() {
    if (_workoutTrackingEnabled) {
      return LocationTrackingMode.workout;
    }
    if (ref.read(appTabProvider) == AppTab.running) {
      return LocationTrackingMode.passive;
    }
    return null;
  }

  void _ingestSample(LiveLocationSample sample) {
    _setSample(sample);
    ref.read(runPlaybackControllerProvider.notifier).ingestLiveSample(sample);
  }

  void _handleTrackingError() {
    unawaited(
      _stopTracking().then((_) {
        if (ref.mounted) {
          return _syncTracking();
        }
      }),
    );
    if (!ref.mounted) {
      return;
    }
    if (ref.read(runPlaybackControllerProvider).status ==
        RunScreenStatus.running) {
      unawaited(ref.read(runPlaybackControllerProvider.notifier).stop());
    }
  }

  Future<void> _stopTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _activeTrackingMode = null;
  }

  void _setSample(LiveLocationSample sample) {
    _latestSample = sample;
    state = sample;
  }
}

final liveLocationProvider =
    NotifierProvider<LiveLocationController, LiveLocationSample?>(
      LiveLocationController.new,
    );

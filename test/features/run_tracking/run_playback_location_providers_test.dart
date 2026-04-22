import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';

import 'run_playback_provider_harness.dart';

void main() {
  test('bootstrap initial location prefers the last known sample', () async {
    final lastKnownSample = playbackSample(
      latitude: 37.51,
      longitude: 127.01,
      capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
    );
    final deviceLocationClient = TestDeviceLocationClient(
      lastKnownResponses: <Future<LiveLocationSample?>>[
        Future<LiveLocationSample?>.value(lastKnownSample),
      ],
      currentResponses: <Future<LiveLocationSample?>>[
        Future<LiveLocationSample?>.value(
          playbackSample(
            latitude: 37.52,
            longitude: 127.02,
            capturedAt: DateTime(2026, 4, 20, 6, 0, 3),
          ),
        ),
      ],
    );
    final streamClient = TrackingLocationStreamClient();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(deviceLocationClient),
        locationStreamClientProvider.overrideWithValue(streamClient),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    final bootstrappedSample = await container
        .read(liveLocationProvider.notifier)
        .bootstrapInitialLocation();

    expect(bootstrappedSample, lastKnownSample);
    expect(container.read(liveLocationProvider), lastKnownSample);
    expect(deviceLocationClient.lastKnownFetchCount, 1);
    expect(deviceLocationClient.currentFetchCount, 0);
  });

  test('bootstrap initial location falls back to the current sample', () async {
    final currentSample = playbackSample(
      latitude: 37.53,
      longitude: 127.03,
      capturedAt: DateTime(2026, 4, 20, 6, 0, 5),
    );
    final deviceLocationClient = TestDeviceLocationClient(
      currentResponses: <Future<LiveLocationSample?>>[
        Future<LiveLocationSample?>.value(currentSample),
      ],
    );
    final streamClient = TrackingLocationStreamClient();
    final container = ProviderContainer(
      overrides: [
        deviceLocationClientProvider.overrideWithValue(deviceLocationClient),
        locationStreamClientProvider.overrideWithValue(streamClient),
      ],
    );
    addTearDown(() async {
      await streamClient.close();
      container.dispose();
    });

    final bootstrappedSample = await container
        .read(liveLocationProvider.notifier)
        .bootstrapInitialLocation();

    expect(bootstrappedSample, currentSample);
    expect(container.read(liveLocationProvider), currentSample);
    expect(deviceLocationClient.lastKnownFetchCount, 1);
    expect(deviceLocationClient.currentFetchCount, 1);
  });

  test(
    'bootstrap initial location still tries current sample after a last-known failure',
    () async {
      final currentSample = playbackSample(
        latitude: 37.53,
        longitude: 127.03,
        capturedAt: DateTime(2026, 4, 20, 6, 0, 5),
      );
      final deviceLocationClient = TestDeviceLocationClient(
        lastKnownResponses: <Future<LiveLocationSample?>>[
          Future<LiveLocationSample?>.error(StateError('last known failed')),
        ],
        currentResponses: <Future<LiveLocationSample?>>[
          Future<LiveLocationSample?>.value(currentSample),
        ],
      );
      final streamClient = TrackingLocationStreamClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(deviceLocationClient),
          locationStreamClientProvider.overrideWithValue(streamClient),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      final bootstrappedSample = await container
          .read(liveLocationProvider.notifier)
          .bootstrapInitialLocation();

      expect(bootstrappedSample, currentSample);
      expect(container.read(liveLocationProvider), currentSample);
      expect(deviceLocationClient.lastKnownFetchCount, 1);
      expect(deviceLocationClient.currentFetchCount, 1);
    },
  );

  test(
    'prepare quick recenter target falls back to the last known sample',
    () async {
      final lastKnownSample = playbackSample(
        latitude: 37.51,
        longitude: 127.01,
        capturedAt: DateTime(2026, 4, 20, 6, 0, 0),
      );
      final deviceLocationClient = TestDeviceLocationClient(
        lastKnownResponses: <Future<LiveLocationSample?>>[
          Future<LiveLocationSample?>.value(lastKnownSample),
        ],
      );
      final streamClient = TrackingLocationStreamClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(deviceLocationClient),
          locationStreamClientProvider.overrideWithValue(streamClient),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      final quickTarget = await container
          .read(liveLocationProvider.notifier)
          .prepareQuickRecenterTarget();

      expect(quickTarget, lastKnownSample);
      expect(container.read(liveLocationProvider), lastKnownSample);
      expect(deviceLocationClient.lastKnownFetchCount, 1);
      expect(deviceLocationClient.currentFetchCount, 0);
    },
  );

  test(
    'bootstrap initial location keeps null when current fetch times out',
    () async {
      final pendingCurrentSample = Completer<LiveLocationSample?>();
      final deviceLocationClient = TestDeviceLocationClient(
        currentResponses: <Future<LiveLocationSample?>>[
          pendingCurrentSample.future,
        ],
      );
      final streamClient = TrackingLocationStreamClient();
      final container = ProviderContainer(
        overrides: [
          deviceLocationClientProvider.overrideWithValue(deviceLocationClient),
          locationStreamClientProvider.overrideWithValue(streamClient),
          startupCurrentLocationTimeoutProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
        ],
      );
      addTearDown(() async {
        await streamClient.close();
        container.dispose();
      });

      final bootstrappedSample = await container
          .read(liveLocationProvider.notifier)
          .bootstrapInitialLocation();

      expect(bootstrappedSample, isNull);
      expect(container.read(liveLocationProvider), isNull);
      expect(deviceLocationClient.lastKnownFetchCount, 1);
      expect(deviceLocationClient.currentFetchCount, 1);
    },
  );
}

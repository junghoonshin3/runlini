import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

abstract class DeviceLocationClient {
  Future<LiveLocationSample?> fetchLastKnownSample();

  Future<LiveLocationSample?> fetchCurrentSample();
}

abstract class LocationStreamClient implements DeviceLocationClient {
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
  });
}

enum LocationTrackingMode {
  passive(androidInterval: Duration(seconds: 3), distanceFilterM: 5),
  workout(androidInterval: Duration(seconds: 1), distanceFilterM: 3);

  const LocationTrackingMode({
    required this.androidInterval,
    required this.distanceFilterM,
  });

  final Duration androidInterval;
  final int distanceFilterM;

  bool get usesBackgroundTracking => this == LocationTrackingMode.workout;
}

class GeolocatorRunLocationClient
    implements DeviceLocationClient, LocationStreamClient {
  const GeolocatorRunLocationClient();

  @override
  Future<LiveLocationSample?> fetchLastKnownSample() async {
    final ready = await _ensureReady();
    if (!ready) {
      return null;
    }

    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        return null;
      }
      return _toLiveLocationSample(position);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LiveLocationSample?> fetchCurrentSample() async {
    final ready = await _ensureReady();
    if (!ready) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      return _toLiveLocationSample(position);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<LiveLocationSample> watchLocationSamples({
    LocationTrackingMode mode = LocationTrackingMode.passive,
  }) async* {
    final ready = await _ensureReady();
    if (!ready) {
      return;
    }

    yield* Geolocator.getPositionStream(
      locationSettings: _streamLocationSettings(mode),
    ).map(_toLiveLocationSample);
  }

  Future<bool> _ensureReady() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    } catch (error) {
      debugPrint('Runlini location readiness check failed: $error');
      return false;
    }
  }

  LocationSettings _streamLocationSettings(LocationTrackingMode mode) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: mode.distanceFilterM,
          intervalDuration: mode.androidInterval,
          foregroundNotificationConfig: mode.usesBackgroundTracking
              ? const ForegroundNotificationConfig(
                  notificationTitle: 'Runlini is tracking your run',
                  notificationText:
                      'Location tracking stays on during your run.',
                  notificationChannelName: 'Run Tracking',
                  enableWakeLock: true,
                  setOngoing: true,
                )
              : null,
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType: ActivityType.fitness,
          distanceFilter: mode.distanceFilterM,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: mode.usesBackgroundTracking,
          showBackgroundLocationIndicator: mode.usesBackgroundTracking,
        );
      default:
        return LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: mode.distanceFilterM,
        );
    }
  }

  LiveLocationSample _toLiveLocationSample(Position position) {
    return LiveLocationSample(
      latitude: position.latitude,
      longitude: position.longitude,
      capturedAt: position.timestamp,
      source: RunPointSource.deviceGps,
      paceSecPerKm: _paceFromSpeed(position.speed),
      speedMps: position.speed > 0 ? position.speed : null,
      elevationM: position.altitude.isFinite ? position.altitude : null,
    );
  }

  double? _paceFromSpeed(double speedMetersPerSecond) {
    if (speedMetersPerSecond <= 0) {
      return null;
    }

    return 1000 / speedMetersPerSecond;
  }
}

final deviceLocationClientProvider = Provider<DeviceLocationClient>(
  (Ref ref) => const GeolocatorRunLocationClient(),
);

final locationStreamClientProvider = Provider<LocationStreamClient>(
  (Ref ref) => const GeolocatorRunLocationClient(),
);

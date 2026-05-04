import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';

abstract class WatchIntervalConfigClient {
  Future<void> sendIntervalWorkout(RunIntervalWorkout workout);
}

class MethodChannelWatchIntervalConfigClient
    implements WatchIntervalConfigClient {
  const MethodChannelWatchIntervalConfigClient({bool? isAndroidOverride})
    : _isAndroidOverride = isAndroidOverride;

  static const MethodChannel _channel = MethodChannel(
    'runlini/wear_interval_config',
  );

  final bool? _isAndroidOverride;

  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  @override
  Future<void> sendIntervalWorkout(RunIntervalWorkout workout) async {
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('sendIntervalConfig', <String, Object?>{
        'enabled': workout.enabled,
        'json': jsonEncode(workout.toJson()),
      });
    } on MissingPluginException {
      return;
    }
  }
}

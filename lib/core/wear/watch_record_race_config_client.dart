import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:runlini/features/run_tracking/types/watch_record_race_config.dart';

abstract class WatchRecordRaceConfigClient {
  Future<void> sendRecordRaceConfig(WatchRecordRaceConfig config);
  Future<void> sendRecordRaceConfigs({
    required String? activeId,
    required List<WatchRecordRaceConfig> configs,
  });
  Future<void> clearRecordRaceConfig();
}

class MethodChannelWatchRecordRaceConfigClient
    implements WatchRecordRaceConfigClient {
  const MethodChannelWatchRecordRaceConfigClient({bool? isAndroidOverride})
    : _isAndroidOverride = isAndroidOverride;

  static const MethodChannel _channel = MethodChannel(
    'runlini/wear_record_race_config',
  );

  final bool? _isAndroidOverride;

  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  @override
  Future<void> sendRecordRaceConfig(WatchRecordRaceConfig config) async {
    if (!_isAndroid || !config.canRunOnWatch) {
      return;
    }

    try {
      await _channel.invokeMethod<void>(
        'sendRecordRaceConfig',
        <String, Object?>{'id': config.id, 'json': jsonEncode(config.toJson())},
      );
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> sendRecordRaceConfigs({
    required String? activeId,
    required List<WatchRecordRaceConfig> configs,
  }) async {
    if (!_isAndroid) {
      return;
    }

    final runnableConfigs = configs
        .where((WatchRecordRaceConfig config) => config.canRunOnWatch)
        .take(3)
        .toList(growable: false);
    final activeIdIsRunnable =
        activeId != null &&
        runnableConfigs.any(
          (WatchRecordRaceConfig config) => config.id == activeId,
        );
    final resolvedActiveId = activeIdIsRunnable
        ? activeId
        : (runnableConfigs.isEmpty ? null : runnableConfigs.first.id);
    final payload = <String, Object?>{
      'activeId': resolvedActiveId,
      'configs': runnableConfigs
          .map((WatchRecordRaceConfig config) => config.toJson())
          .toList(growable: false),
    };

    try {
      await _channel.invokeMethod<void>(
        'sendRecordRaceConfigs',
        <String, Object?>{
          'activeId': resolvedActiveId,
          'json': jsonEncode(payload),
        },
      );
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> clearRecordRaceConfig() async {
    if (!_isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('clearRecordRaceConfig');
    } on MissingPluginException {
      return;
    }
  }
}

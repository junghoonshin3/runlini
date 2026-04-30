import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:runlini/features/run_tracking/types/watch_ghost_config.dart';

abstract class WatchGhostConfigClient {
  Future<void> sendGhostConfig(WatchGhostConfig config);
  Future<void> sendGhostConfigs({
    required String? activeId,
    required List<WatchGhostConfig> configs,
  });
  Future<void> clearGhostConfig();
}

class MethodChannelWatchGhostConfigClient implements WatchGhostConfigClient {
  const MethodChannelWatchGhostConfigClient({bool? isAndroidOverride})
    : _isAndroidOverride = isAndroidOverride;

  static const MethodChannel _channel = MethodChannel(
    'runlini/wear_ghost_config',
  );

  final bool? _isAndroidOverride;

  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  @override
  Future<void> sendGhostConfig(WatchGhostConfig config) async {
    if (!_isAndroid || !config.canRunOnWatch) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('sendGhostConfig', <String, Object?>{
        'id': config.id,
        'json': jsonEncode(config.toJson()),
      });
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> sendGhostConfigs({
    required String? activeId,
    required List<WatchGhostConfig> configs,
  }) async {
    if (!_isAndroid) {
      return;
    }

    final runnableConfigs = configs
        .where((WatchGhostConfig config) => config.canRunOnWatch)
        .take(3)
        .toList(growable: false);
    final activeIdIsRunnable =
        activeId != null &&
        runnableConfigs.any((WatchGhostConfig config) => config.id == activeId);
    final resolvedActiveId = activeIdIsRunnable
        ? activeId
        : (runnableConfigs.isEmpty ? null : runnableConfigs.first.id);
    final payload = <String, Object?>{
      'activeId': resolvedActiveId,
      'configs': runnableConfigs
          .map((WatchGhostConfig config) => config.toJson())
          .toList(growable: false),
    };

    try {
      await _channel.invokeMethod<void>('sendGhostConfigs', <String, Object?>{
        'activeId': resolvedActiveId,
        'json': jsonEncode(payload),
      });
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> clearGhostConfig() async {
    if (!_isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('clearGhostConfig');
    } on MissingPluginException {
      return;
    }
  }
}

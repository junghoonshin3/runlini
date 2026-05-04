import 'dart:io';

import 'package:flutter/services.dart';

enum WatchConnectionStatus { connected, disconnected, unavailable }

abstract class WatchConnectionClient {
  Future<WatchConnectionStatus> connectionStatus();
}

class MethodChannelWatchConnectionClient implements WatchConnectionClient {
  const MethodChannelWatchConnectionClient({bool? isAndroidOverride})
    : _isAndroidOverride = isAndroidOverride;

  static const MethodChannel _channel = MethodChannel(
    'runlini/watch_connection',
  );

  final bool? _isAndroidOverride;

  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  @override
  Future<WatchConnectionStatus> connectionStatus() async {
    if (!_isAndroid) {
      return WatchConnectionStatus.unavailable;
    }

    try {
      final status = await _channel.invokeMethod<String>('connectionStatus');
      return _decodeStatus(status);
    } on MissingPluginException {
      return WatchConnectionStatus.unavailable;
    } on PlatformException {
      return WatchConnectionStatus.disconnected;
    }
  }

  WatchConnectionStatus _decodeStatus(String? status) {
    return switch (status) {
      'connected' => WatchConnectionStatus.connected,
      'disconnected' => WatchConnectionStatus.disconnected,
      _ => WatchConnectionStatus.unavailable,
    };
  }
}

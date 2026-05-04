import 'dart:io';

import 'package:flutter/services.dart';

abstract class WatchVoiceSettingsClient {
  Future<void> sendVoiceSettings({
    required bool voiceCueEnabled,
    required bool kmVoiceCueEnabled,
    required bool ghostVoiceCueEnabled,
    required bool autoPauseEnabled,
    required double volume,
    bool playTestCue = false,
  });
}

class MethodChannelWatchVoiceSettingsClient
    implements WatchVoiceSettingsClient {
  const MethodChannelWatchVoiceSettingsClient({bool? isAndroidOverride})
    : _isAndroidOverride = isAndroidOverride;

  static const MethodChannel _channel = MethodChannel(
    'runlini/wear_voice_settings',
  );

  final bool? _isAndroidOverride;

  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;

  @override
  Future<void> sendVoiceSettings({
    required bool voiceCueEnabled,
    required bool kmVoiceCueEnabled,
    required bool ghostVoiceCueEnabled,
    required bool autoPauseEnabled,
    required double volume,
    bool playTestCue = false,
  }) async {
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('sendVoiceSettings', <String, Object?>{
        'voiceCueEnabled': voiceCueEnabled,
        'kmVoiceCueEnabled': kmVoiceCueEnabled,
        'ghostVoiceCueEnabled': ghostVoiceCueEnabled,
        'autoPauseEnabled': autoPauseEnabled,
        'volume': volume.clamp(0, 1).toDouble(),
        'playTestCue': playTestCue,
      });
    } on MissingPluginException {
      return;
    }
  }
}

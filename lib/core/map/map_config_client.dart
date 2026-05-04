import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');

abstract class MapConfigClient {
  Future<bool> isAndroidGoogleMapsConfigured();
}

class MethodChannelMapConfigClient implements MapConfigClient {
  const MethodChannelMapConfigClient();

  static const MethodChannel _channel = MethodChannel('runlini/map_config');

  @override
  Future<bool> isAndroidGoogleMapsConfigured() async {
    try {
      final configured = await _channel.invokeMethod<bool>(
        'isAndroidGoogleMapsConfigured',
      );
      return configured ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}

final mapConfigClientProvider = Provider<MapConfigClient>(
  (Ref ref) => const MethodChannelMapConfigClient(),
);

final androidGoogleMapsConfiguredProvider = FutureProvider<bool>((Ref ref) {
  if (_isFlutterTest || !Platform.isAndroid) {
    return Future<bool>.value(true);
  }

  return ref.watch(mapConfigClientProvider).isAndroidGoogleMapsConfigured();
});

final runMapControlsReadyProvider = Provider<bool>((Ref ref) {
  if (_isFlutterTest || !Platform.isAndroid) {
    return true;
  }
  return ref
      .watch(androidGoogleMapsConfiguredProvider)
      .maybeWhen(data: (configured) => configured, orElse: () => false);
});

// 러닝 시작 전 움직임 감지 권한 상태와 요청을 추상화하는 클라이언트
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RunMotionPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

abstract class RunMotionPermissionClient {
  Future<RunMotionPermissionStatus> checkActivityRecognitionPermission();

  Future<RunMotionPermissionStatus> requestActivityRecognitionPermission();

  Future<void> openAppSettings();
}

class PlatformRunMotionPermissionClient implements RunMotionPermissionClient {
  const PlatformRunMotionPermissionClient({
    MethodChannel channel = const MethodChannel('runlini/motion_permission'),
    bool useChannelInFlutterTests = false,
  }) : _channel = channel,
       _useChannelInFlutterTests = useChannelInFlutterTests;

  final MethodChannel _channel;
  final bool _useChannelInFlutterTests;

  @override
  Future<RunMotionPermissionStatus> checkActivityRecognitionPermission() {
    return _invokeStatus('checkActivityRecognitionPermission');
  }

  @override
  Future<RunMotionPermissionStatus> requestActivityRecognitionPermission() {
    return _invokeStatus('requestActivityRecognitionPermission');
  }

  @override
  Future<void> openAppSettings() async {
    if (!_shouldUsePlatformChannel) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } catch (_) {
      return;
    }
  }

  Future<RunMotionPermissionStatus> _invokeStatus(String method) async {
    if (!_shouldUsePlatformChannel) {
      return RunMotionPermissionStatus.granted;
    }
    try {
      final value = await _channel.invokeMethod<String>(method);
      return _statusFromPlatform(value);
    } catch (_) {
      return RunMotionPermissionStatus.unavailable;
    }
  }

  bool get _shouldUsePlatformChannel {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (Platform.environment.containsKey('FLUTTER_TEST') &&
        !_useChannelInFlutterTests) {
      return false;
    }
    var hasFlutterBinding = true;
    assert(() {
      hasFlutterBinding = BindingBase.debugBindingType() != null;
      return true;
    }());
    return hasFlutterBinding;
  }

  RunMotionPermissionStatus _statusFromPlatform(String? value) {
    return switch (value) {
      'granted' => RunMotionPermissionStatus.granted,
      'denied' => RunMotionPermissionStatus.denied,
      'permanentlyDenied' => RunMotionPermissionStatus.permanentlyDenied,
      _ => RunMotionPermissionStatus.unavailable,
    };
  }
}

final runMotionPermissionClientProvider = Provider<RunMotionPermissionClient>(
  (Ref ref) => const PlatformRunMotionPermissionClient(),
);

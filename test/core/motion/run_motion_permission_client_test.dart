// 움직임 감지 권한 MethodChannel 클라이언트 매핑을 검증한다
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/motion/run_motion_permission_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('runlini/motion_permission');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps activity recognition permission statuses', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return switch (call.method) {
            'checkActivityRecognitionPermission' => 'denied',
            'requestActivityRecognitionPermission' => 'granted',
            _ => null,
          };
        });

    const client = PlatformRunMotionPermissionClient(
      channel: channel,
      useChannelInFlutterTests: true,
    );

    expect(
      await client.checkActivityRecognitionPermission(),
      RunMotionPermissionStatus.denied,
    );
    expect(
      await client.requestActivityRecognitionPermission(),
      RunMotionPermissionStatus.granted,
    );
  });

  test('maps permanently denied and unknown results safely', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'permanentlyDenied');

    const client = PlatformRunMotionPermissionClient(
      channel: channel,
      useChannelInFlutterTests: true,
    );

    expect(
      await client.checkActivityRecognitionPermission(),
      RunMotionPermissionStatus.permanentlyDenied,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'unexpected');

    expect(
      await client.checkActivityRecognitionPermission(),
      RunMotionPermissionStatus.unavailable,
    );
  });

  test('handles channel failures as unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'motion_error');
        });

    const client = PlatformRunMotionPermissionClient(
      channel: channel,
      useChannelInFlutterTests: true,
    );

    expect(
      await client.requestActivityRecognitionPermission(),
      RunMotionPermissionStatus.unavailable,
    );
  });

  test('opens app settings through the platform channel', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return null;
        });

    const client = PlatformRunMotionPermissionClient(
      channel: channel,
      useChannelInFlutterTests: true,
    );
    await client.openAppSettings();

    expect(calls, <String>['openAppSettings']);
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/wear/watch_interval_config_client.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('runlini/wear_interval_config');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends interval workout over the Android method channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchIntervalConfigClient(
      isAndroidOverride: true,
    );

    await client.sendIntervalWorkout(
      const RunIntervalWorkout(enabled: true, repeatCount: 6),
    );

    expect(calls.single.method, 'sendIntervalConfig');
    expect(calls.single.arguments, containsPair('enabled', true));
    expect(calls.single.arguments.toString(), contains('"repeatCount":6'));
  });

  test('does nothing on non-Android platforms', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchIntervalConfigClient(
      isAndroidOverride: false,
    );

    await client.sendIntervalWorkout(
      const RunIntervalWorkout(enabled: true, repeatCount: 6),
    );

    expect(calls, isEmpty);
  });
}

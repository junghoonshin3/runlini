import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/wear/watch_ghost_config_client.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/watch_ghost_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('runlini/wear_ghost_config');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends runnable ghost config over the Android method channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchGhostConfigClient(isAndroidOverride: true);

    await client.sendGhostConfig(_config());

    expect(calls.single.method, 'sendGhostConfig');
    expect(calls.single.arguments, containsPair('id', 'ghost-1'));
    expect(calls.single.arguments.toString(), contains('"points"'));
  });

  test('clears ghost config over the Android method channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchGhostConfigClient(isAndroidOverride: true);

    await client.clearGhostConfig();

    expect(calls.single.method, 'clearGhostConfig');
  });

  test('sends recent ghost configs over the Android method channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchGhostConfigClient(isAndroidOverride: true);

    await client.sendGhostConfigs(
      activeId: 'ghost-1',
      configs: [
        _config(),
        _config(id: 'ghost-2'),
        _config(id: 'ghost-3'),
      ],
    );

    expect(calls.single.method, 'sendGhostConfigs');
    expect(calls.single.arguments, containsPair('activeId', 'ghost-1'));
    expect(calls.single.arguments.toString(), contains('"configs"'));
    expect(calls.single.arguments.toString(), contains('"timestampRelMs"'));
  });

  test('sends an empty recent ghost batch as a clear intent', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchGhostConfigClient(isAndroidOverride: true);

    await client.sendGhostConfigs(activeId: null, configs: const []);

    expect(calls.single.method, 'sendGhostConfigs');
    expect(calls.single.arguments, containsPair('activeId', null));
    expect(calls.single.arguments.toString(), contains('"configs":[]'));
  });

  test('does nothing on non-Android platforms', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchGhostConfigClient(
      isAndroidOverride: false,
    );

    await client.sendGhostConfig(_config());
    await client.sendGhostConfigs(activeId: 'ghost-1', configs: [_config()]);
    await client.clearGhostConfig();

    expect(calls, isEmpty);
  });
}

WatchGhostConfig _config({String id = 'ghost-1'}) {
  return WatchGhostConfig(
    id: id,
    startedAt: DateTime.utc(2026, 4, 28, 7),
    durationMs: 600000,
    distanceM: 2000,
    sourceSummary: '한강 2K',
    points: const <RunPoint>[
      RunPoint(
        latitude: 37,
        longitude: 127,
        timestampRelMs: 0,
        source: RunPointSource.deviceGps,
      ),
      RunPoint(
        latitude: 37.001,
        longitude: 127.001,
        timestampRelMs: 600000,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}

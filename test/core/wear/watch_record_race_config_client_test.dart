import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/wear/watch_record_race_config_client.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/watch_record_race_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('runlini/wear_record_race_config');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'sends runnable recordRace config over the Android method channel',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            calls.add(call);
            return null;
          });
      const client = MethodChannelWatchRecordRaceConfigClient(
        isAndroidOverride: true,
      );

      await client.sendRecordRaceConfig(_config());

      expect(calls.single.method, 'sendRecordRaceConfig');
      expect(calls.single.arguments, containsPair('id', 'record-race-1'));
      expect(calls.single.arguments.toString(), contains('"points"'));
    },
  );

  test('clears recordRace config over the Android method channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchRecordRaceConfigClient(
      isAndroidOverride: true,
    );

    await client.clearRecordRaceConfig();

    expect(calls.single.method, 'clearRecordRaceConfig');
  });

  test(
    'sends recent recordRace configs over the Android method channel',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            calls.add(call);
            return null;
          });
      const client = MethodChannelWatchRecordRaceConfigClient(
        isAndroidOverride: true,
      );

      await client.sendRecordRaceConfigs(
        activeId: 'record-race-1',
        configs: [
          _config(),
          _config(id: 'record-race-2'),
          _config(id: 'record-race-3'),
        ],
      );

      expect(calls.single.method, 'sendRecordRaceConfigs');
      expect(calls.single.arguments, containsPair('activeId', 'record-race-1'));
      expect(calls.single.arguments.toString(), contains('"configs"'));
      expect(calls.single.arguments.toString(), contains('"timestampRelMs"'));
    },
  );

  test('sends an empty recent recordRace batch as a clear intent', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchRecordRaceConfigClient(
      isAndroidOverride: true,
    );

    await client.sendRecordRaceConfigs(activeId: null, configs: const []);

    expect(calls.single.method, 'sendRecordRaceConfigs');
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
    const client = MethodChannelWatchRecordRaceConfigClient(
      isAndroidOverride: false,
    );

    await client.sendRecordRaceConfig(_config());
    await client.sendRecordRaceConfigs(
      activeId: 'record-race-1',
      configs: [_config()],
    );
    await client.clearRecordRaceConfig();

    expect(calls, isEmpty);
  });
}

WatchRecordRaceConfig _config({String id = 'record-race-1'}) {
  return WatchRecordRaceConfig(
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

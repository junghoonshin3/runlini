import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/wear/watch_connection_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('runlini/watch_connection');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps connected channel result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'connectionStatus');
          return 'connected';
        });

    const client = MethodChannelWatchConnectionClient(isAndroidOverride: true);

    expect(await client.connectionStatus(), WatchConnectionStatus.connected);
  });

  test('maps disconnected and unknown channel results safely', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'disconnected');

    const client = MethodChannelWatchConnectionClient(isAndroidOverride: true);

    expect(await client.connectionStatus(), WatchConnectionStatus.disconnected);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'unexpected');

    expect(await client.connectionStatus(), WatchConnectionStatus.unavailable);
  });

  test('returns unavailable on non-Android platforms', () async {
    const client = MethodChannelWatchConnectionClient(isAndroidOverride: false);

    expect(await client.connectionStatus(), WatchConnectionStatus.unavailable);
  });

  test('handles method channel failures as disconnected', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'wear_error');
        });

    const client = MethodChannelWatchConnectionClient(isAndroidOverride: true);

    expect(await client.connectionStatus(), WatchConnectionStatus.disconnected);
  });
}

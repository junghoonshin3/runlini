import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/wear/watch_voice_settings_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('runlini/wear_voice_settings');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends voice volume over the Android method channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchVoiceSettingsClient(
      isAndroidOverride: true,
    );

    await client.sendVoiceSettings(
      voiceCueEnabled: true,
      kmVoiceCueEnabled: false,
      ghostVoiceCueEnabled: true,
      volume: 0.6,
      playTestCue: true,
    );

    expect(calls.single.method, 'sendVoiceSettings');
    expect(calls.single.arguments, containsPair('voiceCueEnabled', true));
    expect(calls.single.arguments, containsPair('kmVoiceCueEnabled', false));
    expect(calls.single.arguments, containsPair('ghostVoiceCueEnabled', true));
    expect(calls.single.arguments, containsPair('volume', 0.6));
    expect(calls.single.arguments, containsPair('playTestCue', true));
  });

  test('clamps voice volume before sending', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchVoiceSettingsClient(
      isAndroidOverride: true,
    );

    await client.sendVoiceSettings(
      voiceCueEnabled: true,
      kmVoiceCueEnabled: true,
      ghostVoiceCueEnabled: false,
      volume: 1.8,
    );

    expect(calls.single.arguments, containsPair('volume', 1.0));
    expect(calls.single.arguments, containsPair('playTestCue', false));
  });

  test('does nothing on non-Android platforms', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
    const client = MethodChannelWatchVoiceSettingsClient(
      isAndroidOverride: false,
    );

    await client.sendVoiceSettings(
      voiceCueEnabled: true,
      kmVoiceCueEnabled: true,
      ghostVoiceCueEnabled: false,
      volume: 0.6,
    );

    expect(calls, isEmpty);
  });
}

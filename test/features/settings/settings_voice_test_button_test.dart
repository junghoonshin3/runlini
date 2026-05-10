// 설정의 폰 음성 테스트 버튼 발화 호출을 검증한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/core/voice/run_voice_cue_client.dart';
import 'package:runlini/features/run_tracking/state/run_voice_cue_providers.dart';
import 'package:runlini/features/settings/ui/settings_voice_test_button.dart';

void main() {
  testWidgets('speaks the phone voice cue test text at current volume', (
    tester,
  ) async {
    final client = _FakeRunVoiceCueClient();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [runVoiceCueClientProvider.overrideWithValue(client)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: SettingsVoiceTestButton(volume: 0.6)),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('phone-voice-cue-test-button')));
    await tester.pump();

    expect(client.spoken, <String>[settingsPhoneVoiceCueTestText]);
    expect(settingsPhoneVoiceCueTestText, isNot(contains(RegExp(r'\d'))));
    expect(client.volumes, <double>[0.6]);
  });
}

class _FakeRunVoiceCueClient implements RunVoiceCueClient {
  final List<String> spoken = <String>[];
  final List<double> volumes = <double>[];

  @override
  Future<void> speak(String text, {required double volume}) async {
    spoken.add(text);
    volumes.add(volume);
  }

  @override
  Future<void> stop() async {}
}

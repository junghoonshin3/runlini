// 폰 음성 안내 테스트 버튼을 렌더링한다
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/state/run_voice_cue_providers.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

const settingsPhoneVoiceCueTestText = '음량 테스트입니다. 폰 안내 음성이 제대로 들립니다.';

class SettingsVoiceTestButton extends ConsumerStatefulWidget {
  const SettingsVoiceTestButton({super.key, required this.volume});

  final double volume;

  @override
  ConsumerState<SettingsVoiceTestButton> createState() =>
      _SettingsVoiceTestButtonState();
}

class _SettingsVoiceTestButtonState
    extends ConsumerState<SettingsVoiceTestButton> {
  bool _speaking = false;

  @override
  Widget build(BuildContext context) {
    return SettingsCompactButton(
      key: const Key('phone-voice-cue-test-button'),
      label: _speaking ? '재생 중' : '폰 음성 테스트',
      onPressed: _speaking ? null : () => unawaited(_speak()),
      expand: true,
    );
  }

  Future<void> _speak() async {
    setState(() {
      _speaking = true;
    });
    try {
      await ref
          .read(runVoiceCueClientProvider)
          .speak(settingsPhoneVoiceCueTestText, volume: widget.volume);
    } finally {
      if (mounted) {
        setState(() {
          _speaking = false;
        });
      }
    }
  }
}

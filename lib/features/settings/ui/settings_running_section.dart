import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

class SettingsRunningSection extends ConsumerWidget {
  const SettingsRunningSection({super.key, required this.settings});

  final RunSettingsState settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(runSettingsControllerProvider.notifier);
    return SettingsSectionPanel(
      title: '러닝',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('위치 업데이트', style: _labelStyle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PresetButton(
                preset: RunLocationTrackingPreset.batterySaver,
                selectedPreset: settings.locationTrackingPreset,
                label: '절전',
                onPressed: controller.setLocationTrackingPreset,
              ),
              _PresetButton(
                preset: RunLocationTrackingPreset.balanced,
                selectedPreset: settings.locationTrackingPreset,
                label: '균형',
                onPressed: controller.setLocationTrackingPreset,
              ),
              _PresetButton(
                preset: RunLocationTrackingPreset.highAccuracy,
                selectedPreset: settings.locationTrackingPreset,
                label: '정확',
                onPressed: controller.setLocationTrackingPreset,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _presetDescription(settings.locationTrackingPreset),
            style: _hintStyle,
          ),
          const SizedBox(height: 18),
          _VoiceCueSwitch(
            switchKey: const Key('auto-pause-enabled-switch'),
            label: '자동 일시정지',
            hint: '멈춰 있으면 시간과 거리 누적을 멈춰요.',
            value: settings.autoPauseEnabled,
            onChanged: controller.setAutoPauseEnabled,
          ),
          const SizedBox(height: 18),
          _GhostMarkerSwitch(
            value: settings.showGhostMarker,
            onChanged: controller.setShowGhostMarker,
          ),
          const SizedBox(height: 18),
          _VoiceCueSwitch(
            switchKey: const Key('voice-cue-enabled-switch'),
            label: '음성 안내',
            hint: '폰 러닝과 워치 러닝의 안내 음성을 켜요.',
            value: settings.voiceCueEnabled,
            onChanged: controller.setVoiceCueEnabled,
          ),
          const SizedBox(height: 18),
          _VoiceCueSwitch(
            switchKey: const Key('km-voice-cue-enabled-switch'),
            label: '1km 안내',
            hint: '1km마다 평균 페이스와 시간을 알려줘요.',
            value: settings.kmVoiceCueEnabled,
            onChanged: controller.setKmVoiceCueEnabled,
          ),
          const SizedBox(height: 18),
          _VoiceCueSwitch(
            switchKey: const Key('ghost-voice-cue-enabled-switch'),
            label: '고스트 음성',
            hint: '고스트 상태가 바뀔 때만 짧게 알려줘요.',
            value: settings.ghostVoiceCueEnabled,
            onChanged: controller.setGhostVoiceCueEnabled,
          ),
          const SizedBox(height: 18),
          _VoiceVolumeSlider(
            value: settings.voiceCueVolume,
            onChanged: controller.setVoiceCueVolume,
          ),
        ],
      ),
    );
  }

  String _presetDescription(RunLocationTrackingPreset preset) {
    return switch (preset) {
      RunLocationTrackingPreset.batterySaver => '배터리를 아끼고 위치는 조금 덜 자주 갱신해요.',
      RunLocationTrackingPreset.balanced =>
        '현재 기본값이에요. 러닝 중 1초 / 3m 기준으로 추적해요.',
      RunLocationTrackingPreset.highAccuracy =>
        '경로를 더 촘촘히 남겨요. 배터리 사용은 늘어날 수 있어요.',
    };
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.preset,
    required this.selectedPreset,
    required this.label,
    required this.onPressed,
  });

  final RunLocationTrackingPreset preset;
  final RunLocationTrackingPreset selectedPreset;
  final String label;
  final ValueChanged<RunLocationTrackingPreset> onPressed;

  @override
  Widget build(BuildContext context) {
    return SettingsCompactButton(
      key: Key('location-preset-${preset.name}-button'),
      label: label,
      selected: selectedPreset == preset,
      onPressed: () => onPressed(preset),
    );
  }
}

class _GhostMarkerSwitch extends StatelessWidget {
  const _GhostMarkerSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('고스트 마커 표시', style: _labelStyle),
              SizedBox(height: 4),
              Text('고스트의 현재 위치를 지도 위에 표시해요.', style: _hintStyle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          key: const Key('show-ghost-marker-switch'),
          value: value,
          activeThumbColor: AppColors.voltGreen,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _VoiceCueSwitch extends StatelessWidget {
  const _VoiceCueSwitch({
    required this.switchKey,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final Key switchKey;
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _labelStyle),
              const SizedBox(height: 4),
              Text(hint, style: _hintStyle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          key: switchKey,
          value: value,
          activeThumbColor: AppColors.voltGreen,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _VoiceVolumeSlider extends StatelessWidget {
  const _VoiceVolumeSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('음성 안내 음량', style: _labelStyle)),
            Text('$percent%', style: _labelStyle),
          ],
        ),
        const SizedBox(height: 4),
        const Text('폰과 워치에서 나오는 안내 음량이에요.', style: _hintStyle),
        Slider(
          key: const Key('voice-cue-volume-slider'),
          value: value.clamp(runVoiceCueVolumeMin, runVoiceCueVolumeMax),
          min: runVoiceCueVolumeMin,
          max: runVoiceCueVolumeMax,
          divisions: 10,
          activeColor: AppColors.voltGreen,
          inactiveColor: AppColors.chalk.withValues(alpha: 0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

const _labelStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);

const _hintStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
  height: 1.35,
);

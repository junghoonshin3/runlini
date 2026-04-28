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
          const Text('시작 카운트다운', style: _labelStyle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (
                var seconds = runCountdownMinSeconds;
                seconds <= runCountdownMaxSeconds;
                seconds += 1
              )
                SettingsCompactButton(
                  key: Key('countdown-seconds-$seconds-button'),
                  label: '$seconds초',
                  selected: settings.countdownSeconds == seconds,
                  onPressed: () => controller.setCountdownSeconds(seconds),
                ),
            ],
          ),
          const SizedBox(height: 18),
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
          _GhostMarkerSwitch(
            value: settings.showGhostMarker,
            onChanged: controller.setShowGhostMarker,
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

const _labelStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);

const _hintStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
  height: 1.35,
);

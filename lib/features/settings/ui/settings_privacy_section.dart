import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

class SettingsPrivacySection extends ConsumerWidget {
  const SettingsPrivacySection({super.key, required this.settings});

  final RunPrivacySettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(runSettingsControllerProvider.notifier);
    return SettingsSectionPanel(
      title: '프라이버시',
      child: Column(
        children: [
          _PrivacySwitch(
            key: const Key('hide-route-map-switch'),
            title: '상세 지도 숨기기',
            value: settings.hideRouteMap,
            onChanged: (value) =>
                controller.setPrivacy(settings.copyWith(hideRouteMap: value)),
          ),
          _PrivacySwitch(
            key: const Key('hide-start-end-area-switch'),
            title: '시작/종료 위치 보호 표시',
            value: settings.hideStartEndArea,
            onChanged: (value) => controller.setPrivacy(
              settings.copyWith(hideStartEndArea: value),
            ),
          ),
          _PrivacySwitch(
            key: const Key('hide-heart-rate-switch'),
            title: '심박 숨기기',
            value: settings.hideHeartRate,
            onChanged: (value) =>
                controller.setPrivacy(settings.copyWith(hideHeartRate: value)),
          ),
          _PrivacySwitch(
            key: const Key('hide-calories-switch'),
            title: '칼로리 숨기기',
            value: settings.hideCalories,
            onChanged: (value) =>
                controller.setPrivacy(settings.copyWith(hideCalories: value)),
          ),
        ],
      ),
    );
  }
}

class _PrivacySwitch extends StatelessWidget {
  const _PrivacySwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: AppColors.chalk)),
      activeThumbColor: AppColors.voltGreen,
      value: value,
      onChanged: onChanged,
    );
  }
}

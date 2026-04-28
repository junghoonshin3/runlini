import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

class SettingsDisplaySection extends ConsumerWidget {
  const SettingsDisplaySection({super.key, required this.settings});

  final RunDisplaySettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSectionPanel(
      title: '기록 표시',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SettingsCompactButton(
            key: const Key('distance-unit-km-button'),
            label: '킬로미터 · min/km · km/h',
            selected: settings.distanceUnit == RunDistanceUnit.km,
            onPressed: () => ref
                .read(runSettingsControllerProvider.notifier)
                .setDistanceUnit(RunDistanceUnit.km),
          ),
          SettingsCompactButton(
            key: const Key('distance-unit-mi-button'),
            label: '마일 · min/mi · mph',
            selected: settings.distanceUnit == RunDistanceUnit.mi,
            onPressed: () => ref
                .read(runSettingsControllerProvider.notifier)
                .setDistanceUnit(RunDistanceUnit.mi),
          ),
        ],
      ),
    );
  }
}

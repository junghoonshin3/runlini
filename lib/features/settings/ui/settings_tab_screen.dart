import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/settings/ui/settings_distance_goal_section.dart';
import 'package:runlini/features/settings/ui/settings_privacy_section.dart';
import 'package:runlini/features/settings/ui/settings_profile_section.dart';
import 'package:runlini/features/settings/ui/settings_running_section.dart';
import 'package:runlini/features/settings/ui/settings_shoe_section.dart';
import 'package:runlini/features/settings/ui/settings_sync_section.dart';

class SettingsTabScreen extends ConsumerWidget {
  const SettingsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(runSettingsControllerProvider).value ??
        const RunSettingsState();

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const Key('settings-tab-screen'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            '설정',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 16),
          SettingsRunningSection(settings: settings),
          const SizedBox(height: 14),
          SettingsRunGuidanceSection(settings: settings),
          const SizedBox(height: 14),
          SettingsDistanceGoalSection(settings: settings),
          const SizedBox(height: 14),
          SettingsProfileSection(settings: settings),
          const SizedBox(height: 14),
          const SettingsShoeSection(),
          const SizedBox(height: 14),
          const SettingsSyncSection(),
          const SizedBox(height: 14),
          SettingsPrivacySection(settings: settings.privacy),
        ],
      ),
    );
  }
}

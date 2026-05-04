import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_image_thumbnail.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';
import 'package:runlini/features/settings/ui/settings_shoe_action_grid.dart';
import 'package:runlini/features/settings/ui/settings_shoe_management_screen.dart';
import 'package:runlini/features/settings/ui/settings_shoe_summary_helpers.dart';

class SettingsShoeSection extends ConsumerWidget {
  const SettingsShoeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoes = ref.watch(runShoeListProvider).value ?? const <RunShoe>[];
    final settings = ref.watch(runSettingsControllerProvider).value;
    final sessions =
        ref.watch(runSessionListProvider).value ?? const <RunSession>[];
    final distanceByShoe = shoeDistanceKmById(sessions);
    final defaultShoe = defaultShoeFor(shoes, settings?.defaultShoeId);

    return SettingsSectionPanel(
      title: '러닝화',
      trailing: SettingsCompactButton(
        key: const Key('manage-shoes-button'),
        onPressed: () => _openManagementScreen(context),
        label: '러닝화 관리',
      ),
      child: defaultShoe == null
          ? const Text('기본 러닝화가 없어요.', style: _mutedStyle)
          : _DefaultShoeSummary(
              shoe: defaultShoe,
              distanceKm: distanceByShoe[defaultShoe.id] ?? 0,
            ),
    );
  }

  void _openManagementScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const SettingsShoeManagementScreen(),
      ),
    );
  }
}

class _DefaultShoeSummary extends StatelessWidget {
  const _DefaultShoeSummary({required this.shoe, required this.distanceKm});

  final RunShoe shoe;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('default-shoe-summary-${shoe.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shoe.imagePath != null) ...[
            RunShoeImageThumbnail(imagePath: shoe.imagePath!, size: 48),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('기본 러닝화', style: _labelStyle),
                const SizedBox(height: 6),
                Text('${shoe.brand} ${shoe.name}', style: _titleStyle),
                const SizedBox(height: 6),
                Text(
                  '${distanceKm.toStringAsFixed(1)} / '
                  '${shoe.distanceLimitKm.toStringAsFixed(0)} km'
                  '${shoe.retired ? ' · 은퇴됨' : ''}',
                  style: _mutedStyle,
                ),
                const SizedBox(height: 10),
                ShoeMileageProgress(
                  distanceKm: distanceKm,
                  limitKm: shoe.distanceLimitKm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _labelStyle = TextStyle(
  color: AppColors.voltGreen,
  fontWeight: FontWeight.w900,
);

const _titleStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);

const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
);

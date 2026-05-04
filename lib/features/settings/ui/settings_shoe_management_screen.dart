import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_form_screen.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_image_thumbnail.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';
import 'package:runlini/features/settings/ui/settings_shoe_action_grid.dart';
import 'package:runlini/features/settings/ui/settings_shoe_courses_screen.dart';
import 'package:runlini/features/settings/ui/settings_shoe_summary_helpers.dart';

class SettingsShoeManagementScreen extends ConsumerWidget {
  const SettingsShoeManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shoes = ref.watch(runShoeListProvider).value ?? const <RunShoe>[];
    final settings = ref.watch(runSettingsControllerProvider).value;
    final sessions =
        ref.watch(runSessionListProvider).value ?? const <RunSession>[];
    final distanceByShoe = shoeDistanceKmById(sessions);
    final activeShoes = shoes
        .where((shoe) => !shoe.deleted)
        .toList(growable: false);

    return Scaffold(
      key: const Key('shoe-management-screen'),
      backgroundColor: AppColors.black,
      appBar: AppBar(title: const Text('러닝화 관리')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '러닝화',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              SettingsCompactButton(
                key: const Key('add-shoe-button'),
                onPressed: () => _openAddShoeScreen(context),
                label: '추가',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeShoes.isEmpty)
            const Text('등록된 러닝화가 없어요.', style: _mutedStyle)
          else
            ...activeShoes.map(
              (shoe) => _ShoeManagementTile(
                shoe: shoe,
                isDefault: settings?.defaultShoeId == shoe.id,
                distanceKm: distanceByShoe[shoe.id] ?? 0,
              ),
            ),
        ],
      ),
    );
  }

  void _openAddShoeScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const RunShoeFormScreen(),
      ),
    );
  }
}

class _ShoeManagementTile extends ConsumerWidget {
  const _ShoeManagementTile({
    required this.shoe,
    required this.isDefault,
    required this.distanceKm,
  });

  final RunShoe shoe;
  final bool isDefault;
  final double distanceKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: Key('shoe-item-${shoe.id}'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShoeManagementHeader(shoe: shoe, distanceKm: distanceKm),
          const SizedBox(height: 12),
          ShoeMileageProgress(
            distanceKm: distanceKm,
            limitKm: shoe.distanceLimitKm,
          ),
          const SizedBox(height: 14),
          ShoeActionGrid(
            children: [
              SettingsCompactButton(
                key: Key('default-shoe-${shoe.id}'),
                onPressed: shoe.retired
                    ? null
                    : () => ref
                          .read(runSettingsControllerProvider.notifier)
                          .setDefaultShoeId(shoe.id),
                selected: isDefault,
                expand: true,
                label: isDefault ? '기본 러닝화' : '기본 선택',
              ),
              SettingsCompactButton(
                key: Key('shoe-courses-${shoe.id}'),
                onPressed: () => _openShoeCourses(context),
                expand: true,
                label: '착용 기록',
              ),
              SettingsCompactButton(
                key: Key('edit-shoe-${shoe.id}'),
                onPressed: () => _openEditShoe(context),
                expand: true,
                label: '수정',
              ),
              if (!shoe.retired)
                SettingsCompactButton(
                  key: Key('retire-shoe-${shoe.id}'),
                  onPressed: () => ref
                      .read(runSettingsControllerProvider.notifier)
                      .retireShoe(shoe.id),
                  danger: true,
                  expand: true,
                  label: '은퇴',
                ),
              SettingsCompactButton(
                key: Key('delete-shoe-${shoe.id}'),
                onPressed: () => _confirmDeleteShoe(context, ref),
                danger: true,
                expand: true,
                label: '삭제',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteShoe(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(runSettingsControllerProvider.notifier);
    final hasMileage = distanceKm > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('러닝화 삭제'),
        content: Text(
          hasMileage
              ? '이 러닝화에는 ${distanceKm.toStringAsFixed(1)} km 기록이 '
                    '연결되어 있어요. 삭제해도 과거 기록의 러닝화 이름은 '
                    '유지되고, 앞으로 선택 목록에서만 사라져요.'
              : '이 러닝화를 선택 목록에서 삭제할까요?',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-delete-shoe-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const Key('confirm-delete-shoe-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteShoe(shoe.id);
    }
  }

  void _openShoeCourses(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsShoeCoursesScreen(shoe: shoe),
      ),
    );
  }

  void _openEditShoe(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RunShoeFormScreen(shoe: shoe),
      ),
    );
  }
}

class _ShoeManagementHeader extends StatelessWidget {
  const _ShoeManagementHeader({required this.shoe, required this.distanceKm});

  final RunShoe shoe;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shoe.imagePath != null) ...[
          RunShoeImageThumbnail(
            key: Key('shoe-image-thumbnail-${shoe.id}'),
            imagePath: shoe.imagePath!,
            size: 58,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${shoe.brand} ${shoe.name}', style: _titleStyle),
              const SizedBox(height: 6),
              Text(
                '${distanceKm.toStringAsFixed(1)} / '
                '${shoe.distanceLimitKm.toStringAsFixed(0)} km'
                '${shoe.retired ? ' · 은퇴됨' : ''}',
                style: _mutedStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _titleStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);

const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
);

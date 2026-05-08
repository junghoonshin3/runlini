import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_session_detail_screen.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/history/run_session_summary_tile.dart';
import 'package:runlini/features/settings/ui/settings_shoe_courses_skeleton.dart';

class SettingsShoeCoursesScreen extends ConsumerWidget {
  const SettingsShoeCoursesScreen({super.key, required this.shoe});

  final RunShoe shoe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    final sessionsAsync = ref.watch(runSessionListProvider);
    return Scaffold(
      key: const Key('shoe-courses-screen'),
      backgroundColor: AppColors.black,
      appBar: AppBar(title: const Text('러닝화 기록')),
      body: sessionsAsync.when(
        data: (sessions) {
          final shoeSessions = sessions
              .where((session) => session.shoeId == shoe.id)
              .toList(growable: false);
          final totalDistanceM = shoeSessions.fold<double>(
            0,
            (sum, session) => sum + session.distanceM,
          );
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            itemCount: shoeSessions.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ShoeCoursesHeader(
                  shoe: shoe,
                  runCount: shoeSessions.length,
                  totalDistanceM: totalDistanceM,
                  displaySettings: displaySettings,
                );
              }
              final session = shoeSessions[index - 1];
              return RunSessionSummaryTile(
                key: Key('shoe-course-${session.id}'),
                summary: RunSessionSummary.fromSession(session),
                displaySettings: displaySettings,
                onTap: () => _openDetail(context, ref, session),
              );
            },
          );
        },
        loading: () => const SettingsShoeCoursesSkeleton(),
        error: (_, _) => const Center(child: Text('기록을 불러오지 못했어요.')),
      ),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    RunSession session,
  ) async {
    final result = await Navigator.of(context).push<RunSessionDetailResult>(
      MaterialPageRoute<RunSessionDetailResult>(
        builder: (context) => RunSessionDetailScreen(session: session),
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }
    ref.invalidate(runSessionListProvider);
    ref.invalidate(runSessionSummaryListProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }
}

class _ShoeCoursesHeader extends StatelessWidget {
  const _ShoeCoursesHeader({
    required this.shoe,
    required this.runCount,
    required this.totalDistanceM,
    required this.displaySettings,
  });

  final RunShoe shoe;
  final int runCount;
  final double totalDistanceM;
  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${shoe.brand} ${shoe.name}', style: _titleStyle(context)),
          const SizedBox(height: 8),
          Text(
            '$runCount개 기록 · '
            '${formatRunDistance(totalDistanceM, displaySettings, decimals: 2)}',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
          ),
          if (runCount == 0) ...[
            const SizedBox(height: 14),
            const Text(
              '이 러닝화로 저장된 기록이 없어요.',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle? _titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge?.copyWith(
      color: AppColors.chalk,
      fontWeight: FontWeight.w900,
    );
  }
}

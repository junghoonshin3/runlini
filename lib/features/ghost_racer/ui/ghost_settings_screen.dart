import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/ghost_racer/state/ghost_racer_providers.dart';
import 'package:runlini/features/ghost_racer/ui/ghost_session_picker_sheet.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/ui/run_session_summary_tile.dart';

class GhostSettingsScreen extends ConsumerWidget {
  const GhostSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(ghostSettingsProvider);
    final summariesAsync = ref.watch(runSessionSummaryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: summariesAsync.when(
          data: (List<RunSessionSummary> summaries) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  '고스트 라이더',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 10),
                Text(
                  '켜면 이전 러닝을 지도 위 기준선으로 띄우고, 끄면 바로 정리합니다.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                _GhostToggleTile(
                  enabled: settings.enabled,
                  onChanged: (bool value) async {
                    if (!value) {
                      ref.read(ghostSettingsProvider.notifier).disable();
                      return;
                    }

                    final selectedSummary = await _pickGhostSession(
                      context: context,
                      summaries: summaries,
                    );
                    if (!context.mounted) {
                      return;
                    }

                    if (selectedSummary == null) {
                      ref.read(ghostSettingsProvider.notifier).disable();
                      return;
                    }

                    ref
                        .read(ghostSettingsProvider.notifier)
                        .selectSession(selectedSummary);
                  },
                ),
                const SizedBox(height: 16),
                Text('선택된 기록', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (settings.selectedSessionSummary == null)
                  const _EmptySelectionState()
                else
                  RunSessionSummaryTile(
                    key: const Key('selected-ghost-summary'),
                    summary: settings.selectedSessionSummary!,
                    onTap: () async {
                      final selectedSummary = await _pickGhostSession(
                        context: context,
                        summaries: summaries,
                      );
                      if (!context.mounted || selectedSummary == null) {
                        return;
                      }

                      ref
                          .read(ghostSettingsProvider.notifier)
                          .selectSession(selectedSummary);
                    },
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.voltGreen),
          ),
          error: (Object error, StackTrace stackTrace) =>
              const Center(child: Text('고스트 기록을 불러오지 못했어요.')),
        ),
      ),
    );
  }

  Future<RunSessionSummary?> _pickGhostSession({
    required BuildContext context,
    required List<RunSessionSummary> summaries,
  }) {
    return showModalBottomSheet<RunSessionSummary>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return GhostSessionPickerSheet(summaries: summaries);
      },
    );
  }
}

class _GhostToggleTile extends StatelessWidget {
  const _GhostToggleTile({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(
          color: enabled ? AppColors.voltGreen : AppColors.chalk,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('고스트 라이더', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  enabled ? '선택한 기록을 기준선으로 띄우는 중' : '이전 기록 없이 단독으로 측정',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('ghost-toggle'),
            value: enabled,
            activeThumbColor: AppColors.voltGreen,
            activeTrackColor: AppColors.voltGreen.withValues(alpha: 0.45),
            inactiveThumbColor: AppColors.chalk,
            inactiveTrackColor: AppColors.graphite,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EmptySelectionState extends StatelessWidget {
  const _EmptySelectionState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk, width: 3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '고스트를 켜면 여기에서 선택한 러닝 기록이 보입니다.',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
      ),
    );
  }
}

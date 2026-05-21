import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_skeleton.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/record_race/types/record_race_settings_state.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_picker_flow.dart';

class RunRecordRaceControlChip extends ConsumerWidget {
  const RunRecordRaceControlChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(recordRaceSettingsProvider);
    final summariesAsync = ref.watch(runSessionSummaryListProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: summariesAsync.when(
          data: (summaries) {
            final selectedSummary = _selectedSummary(settings, summaries);
            return _RecordRaceControlChipBody(
              selectedSummary: selectedSummary,
              hasRecords: summaries.isNotEmpty,
              onPressed: selectedSummary == null
                  ? (summaries.isEmpty
                        ? null
                        : () => _pickRecordRace(context, ref, summaries))
                  : ref.read(recordRaceSettingsProvider.notifier).disable,
            );
          },
          loading: () => const _RecordRaceControlChipSkeleton(),
          error: (error, stackTrace) =>
              const _RecordRaceControlChipBody.error(),
        ),
      ),
    );
  }

  RunSessionSummary? _selectedSummary(
    RecordRaceSettingsState settings,
    List<RunSessionSummary> summaries,
  ) {
    if (!settings.enabled || settings.selectedSessionId == null) {
      return null;
    }
    for (final summary in summaries) {
      if (summary.id == settings.selectedSessionId) {
        return summary;
      }
    }
    return null;
  }

  Future<void> _pickRecordRace(
    BuildContext context,
    WidgetRef ref,
    List<RunSessionSummary> summaries,
  ) async {
    await openRecordRacePicker(
      context: context,
      ref: ref,
      summaries: summaries,
    );
  }
}

class _RecordRaceControlChipSkeleton extends StatelessWidget {
  const _RecordRaceControlChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('record-race-control-chip-skeleton'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.88),
        border: Border.all(
          color: AppColors.chalk.withValues(alpha: 0.35),
          width: 3,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const RunliniSkeletonText(width: 116, height: 20),
    );
  }
}

class _RecordRaceControlChipBody extends StatelessWidget {
  const _RecordRaceControlChipBody({
    required this.selectedSummary,
    required this.hasRecords,
    this.onPressed,
  }) : label = null;

  const _RecordRaceControlChipBody.error()
    : selectedSummary = null,
      hasRecords = false,
      onPressed = null,
      label = '기록 레이스 OFF';

  final RunSessionSummary? selectedSummary;
  final bool hasRecords;
  final VoidCallback? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final active = selectedSummary != null;
    final accent = active ? AppColors.electricRed : AppColors.chalk;
    final foregroundColor = hasRecords ? accent : AppColors.muted;
    final text =
        label ?? (selectedSummary == null ? '기록 레이스 OFF' : '기록 레이스 ON');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('record-race-control-chip'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.black.withValues(alpha: 0.88),
            border: Border.all(color: foregroundColor, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

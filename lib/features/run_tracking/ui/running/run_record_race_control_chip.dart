import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_skeleton.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/record_race/types/record_race_settings_state.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_picker_flow.dart';

class RunRecordRaceControlChip extends ConsumerWidget {
  const RunRecordRaceControlChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(recordRaceSettingsProvider);
    final summariesAsync = ref.watch(runSessionSummaryListProvider);
    final displaySettings = ref.watch(runDisplaySettingsProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: summariesAsync.when(
          data: (summaries) {
            if (!summaries.any(_isSelectableRecordRaceSummary)) {
              return const SizedBox.shrink();
            }
            final selectedSummary = _selectedSummary(settings, summaries);
            return _RecordRaceControlChipBody(
              selectedSummary: selectedSummary,
              displaySettings: displaySettings,
              onPressed: () => _pickRecordRace(context, ref, summaries),
              onClear: selectedSummary == null
                  ? null
                  : ref.read(recordRaceSettingsProvider.notifier).disable,
            );
          },
          loading: () => const _RecordRaceControlChipSkeleton(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  bool _isSelectableRecordRaceSummary(RunSessionSummary summary) {
    return summary.distanceM > 0 &&
        summary.durationMs > 0 &&
        summary.pointCount >= 2 &&
        summary.averagePaceSecPerKm.isFinite &&
        summary.averagePaceSecPerKm > 0;
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
    required this.displaySettings,
    required this.onPressed,
    this.onClear,
  });

  final RunSessionSummary? selectedSummary;
  final RunDisplaySettings displaySettings;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final active = selectedSummary != null;
    final accent = active ? AppColors.voltGreen : AppColors.chalk;
    final label = active
        ? _selectedSummaryLabel(selectedSummary!, displaySettings)
        : '경쟁레이스 선택';
    final semanticsLabel = active ? '선택된 경쟁레이스 기록 변경' : '경쟁레이스 기록 선택';

    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: InkWell(
          key: const Key('record-race-control-chip'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.88),
              border: Border.all(color: accent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.route_rounded : Icons.flag_rounded,
                  color: accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (active && onClear != null) ...[
                  const SizedBox(width: 6),
                  _RecordRaceClearButton(onPressed: onClear!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _selectedSummaryLabel(
    RunSessionSummary summary,
    RunDisplaySettings settings,
  ) {
    final distance = formatRunDistance(
      summary.distanceM,
      settings,
      decimals: 2,
    );
    final pace = formatRunPaceCompact(summary.averagePaceSecPerKm, settings);
    return '경쟁레이스 · $distance · $pace';
  }
}

class _RecordRaceClearButton extends StatelessWidget {
  const _RecordRaceClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('record-race-clear-button'),
      onPressed: onPressed,
      tooltip: '경쟁레이스 해제',
      icon: const Icon(Icons.close_rounded),
      color: AppColors.chalk,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      iconSize: 18,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.chalk.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

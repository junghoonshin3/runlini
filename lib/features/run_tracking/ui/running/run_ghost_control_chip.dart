import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_skeleton.dart';
import 'package:runlini/features/ghost_racer/state/ghost_racer_providers.dart';
import 'package:runlini/features/ghost_racer/types/ghost_settings_state.dart';
import 'package:runlini/features/ghost_racer/ui/ghost_session_picker_sheet.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/running/run_training_mode_conflict_dialog.dart';

class RunGhostControlChip extends ConsumerWidget {
  const RunGhostControlChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(ghostSettingsProvider);
    final summariesAsync = ref.watch(runSessionSummaryListProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: summariesAsync.when(
          data: (summaries) {
            final selectedSummary = _selectedSummary(settings, summaries);
            return _GhostControlChipBody(
              selectedSummary: selectedSummary,
              hasRecords: summaries.isNotEmpty,
              onPressed: selectedSummary == null
                  ? (summaries.isEmpty
                        ? null
                        : () => _pickGhost(context, ref, summaries))
                  : ref.read(ghostSettingsProvider.notifier).disable,
            );
          },
          loading: () => const _GhostControlChipSkeleton(),
          error: (error, stackTrace) => const _GhostControlChipBody.error(),
        ),
      ),
    );
  }

  RunSessionSummary? _selectedSummary(
    GhostSettingsState settings,
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

  Future<void> _pickGhost(
    BuildContext context,
    WidgetRef ref,
    List<RunSessionSummary> summaries,
  ) async {
    final selectedSummary = await showModalBottomSheet<RunSessionSummary>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 140),
        reverseDuration: Duration(milliseconds: 80),
      ),
      builder: (BuildContext context) {
        return GhostSessionPickerSheet(summaries: summaries);
      },
    );
    if (!context.mounted || selectedSummary == null) {
      return;
    }

    final runSettings =
        ref.read(runSettingsControllerProvider).value ??
        const RunSettingsState();
    final intervalWorkout = runSettings.intervalWorkout;
    if (intervalWorkout.enabled) {
      final confirmed = await confirmDisableIntervalForGhost(context);
      if (!context.mounted || !confirmed) {
        return;
      }
      await ref
          .read(runSettingsControllerProvider.notifier)
          .setIntervalWorkout(intervalWorkout.copyWith(enabled: false));
    }

    ref.read(ghostSettingsProvider.notifier).selectSession(selectedSummary);
  }
}

class _GhostControlChipSkeleton extends StatelessWidget {
  const _GhostControlChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ghost-control-chip-skeleton'),
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

class _GhostControlChipBody extends StatelessWidget {
  const _GhostControlChipBody({
    required this.selectedSummary,
    required this.hasRecords,
    this.onPressed,
  }) : label = null;

  const _GhostControlChipBody.error()
    : selectedSummary = null,
      hasRecords = false,
      onPressed = null,
      label = 'Ghost Run Off';

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
        label ?? (selectedSummary == null ? 'Ghost Run Off' : 'Ghost Run On');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('ghost-control-chip'),
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

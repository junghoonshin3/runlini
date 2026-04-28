import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/ghost_racer/state/ghost_racer_providers.dart';
import 'package:runlini/features/ghost_racer/types/ghost_settings_state.dart';
import 'package:runlini/features/ghost_racer/ui/ghost_session_picker_sheet.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

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
          loading: () => const _GhostControlChipBody.loading(),
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
      builder: (BuildContext context) {
        return GhostSessionPickerSheet(summaries: summaries);
      },
    );
    if (!context.mounted || selectedSummary == null) {
      return;
    }

    ref.read(ghostSettingsProvider.notifier).selectSession(selectedSummary);
  }
}

class _GhostControlChipBody extends StatelessWidget {
  const _GhostControlChipBody({
    required this.selectedSummary,
    required this.hasRecords,
    this.onPressed,
  }) : label = null;

  const _GhostControlChipBody.loading()
    : selectedSummary = null,
      hasRecords = false,
      onPressed = null,
      label = 'Ghost Run Off';

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

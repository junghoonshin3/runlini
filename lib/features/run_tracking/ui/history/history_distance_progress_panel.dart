import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/run_history_distance_summary_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_history_distance_summary.dart';
import 'package:runlini/features/run_tracking/types/run_history_period.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/common/run_panel.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/history/history_distance_ring.dart';

class HistoryDistanceProgressPanel extends StatefulWidget {
  const HistoryDistanceProgressPanel({
    super.key,
    required this.sessions,
    required this.displaySettings,
    required this.distanceGoals,
    this.onChangeGoals,
    this.now,
    this.calculator = const RunHistoryDistanceSummaryCalculator(),
  });

  final List<RunSessionSummary> sessions;
  final RunDisplaySettings displaySettings;
  final RunDistanceGoalSettings distanceGoals;
  final VoidCallback? onChangeGoals;
  final DateTime? now;
  final RunHistoryDistanceSummaryCalculator calculator;

  @override
  State<HistoryDistanceProgressPanel> createState() =>
      _HistoryDistanceProgressPanelState();
}

class _HistoryDistanceProgressPanelState
    extends State<HistoryDistanceProgressPanel> {
  RunHistoryPeriod _selectedPeriod = RunHistoryPeriod.week;

  @override
  Widget build(BuildContext context) {
    final summary = widget.calculator.calculate(
      sessions: widget.sessions,
      period: _selectedPeriod,
      now: widget.now ?? DateTime.now(),
      goalDistanceM: widget.distanceGoals.goalFor(_selectedPeriod),
    );
    return RunPanel(
      key: const Key('history-distance-progress-panel'),
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.voltGreen.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodSelector(
            selectedPeriod: _selectedPeriod,
            onSelected: (RunHistoryPeriod period) {
              setState(() => _selectedPeriod = period);
            },
          ),
          const SizedBox(height: 18),
          Center(
            child: HistoryDistanceRing(
              summary: summary,
              displaySettings: widget.displaySettings,
            ),
          ),
          const SizedBox(height: 16),
          _ProgressMeta(
            summary: summary,
            displaySettings: widget.displaySettings,
            onChangeGoals: widget.onChangeGoals,
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onSelected,
  });

  final RunHistoryPeriod selectedPeriod;
  final ValueChanged<RunHistoryPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: RunHistoryPeriod.values
          .map((RunHistoryPeriod period) {
            final selected = period == selectedPeriod;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: period == RunHistoryPeriod.year ? 0 : 8,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('history-period-${period.name}-button'),
                    onTap: () => onSelected(period),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.voltGreen
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AppColors.voltGreen
                              : AppColors.chalk.withValues(alpha: 0.28),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        period.controlLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: selected ? AppColors.black : AppColors.chalk,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ProgressMeta extends StatelessWidget {
  const _ProgressMeta({
    required this.summary,
    required this.displaySettings,
    required this.onChangeGoals,
  });

  final RunHistoryDistanceSummary summary;
  final RunDisplaySettings displaySettings;
  final VoidCallback? onChangeGoals;

  @override
  Widget build(BuildContext context) {
    final goal = formatRunDistance(summary.goalDistanceM, displaySettings);
    final remainingM = (summary.goalDistanceM - summary.distanceM).clamp(
      0,
      double.infinity,
    );
    final remaining = formatRunDistance(remainingM.toDouble(), displaySettings);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetaPill(label: summary.period.goalLabel, value: goal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetaPill(
                label: summary.hasExceededGoal ? '목표 달성' : '남은 거리',
                value: summary.hasExceededGoal ? '완료' : remaining,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetaPill(label: '러닝 횟수', value: '${summary.runCount}회'),
            ),
          ],
        ),
        if (onChangeGoals != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _GoalChangeButton(onPressed: onChangeGoals!),
          ),
        ],
      ],
    );
  }
}

class _GoalChangeButton extends StatelessWidget {
  const _GoalChangeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('history-change-goals-button'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.chalk.withValues(alpha: 0.35),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '목표 변경',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.chalk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

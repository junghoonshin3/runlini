import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_motion.dart';
import 'package:runlini/features/run_tracking/types/run_history_day_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class HistoryDayProgressCell extends StatelessWidget {
  const HistoryDayProgressCell({
    super.key,
    required this.date,
    required this.dayGoalM,
    required this.displaySettings,
    this.summary,
    this.isSelected = false,
    this.isToday = false,
    this.isOutsideMonth = false,
    this.onTap,
  });

  final DateTime date;
  final RunHistoryDaySummary? summary;
  final double dayGoalM;
  final RunDisplaySettings displaySettings;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasRuns = summary?.hasRuns ?? false;
    final progress = summary?.progressForGoal(dayGoalM) ?? 0;
    final opacity = isOutsideMonth ? 0.35 : 1.0;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: RunliniMotion.enabledDuration(
              context,
              RunliniMotion.shortTransition,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.chalk.withValues(alpha: 0.08)
                  : Colors.transparent,
              border: Border.all(color: _borderColor(hasRuns), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 48,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DayRing(
                            progress: progress,
                            hasRuns: hasRuns,
                            isSelected: isSelected,
                            isToday: isToday,
                            day: date.day,
                          ),
                          const SizedBox(height: 3),
                          SizedBox(
                            height: 11,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                hasRuns
                                    ? _distanceLabel(summary!.distanceM)
                                    : '',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if ((summary?.runCount ?? 0) > 1)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: _RunCountBadge(
                      key: Key('history-calendar-run-count-${_dateKey(date)}'),
                      runCount: summary!.runCount,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _borderColor(bool hasRuns) {
    if (isSelected) {
      return AppColors.chalk;
    }
    if (isToday) {
      return AppColors.voltGreen.withValues(alpha: 0.65);
    }
    if (hasRuns) {
      return AppColors.voltGreen.withValues(alpha: 0.25);
    }
    return AppColors.chalk.withValues(alpha: 0.08);
  }

  String _distanceLabel(double distanceM) {
    final distance = distanceForDisplay(distanceM, displaySettings);
    final unit = distanceUnitLabel(displaySettings);
    final decimals = distance < 10 ? 1 : 0;
    return '${distance.toStringAsFixed(decimals)} $unit';
  }
}

class _DayRing extends StatelessWidget {
  const _DayRing({
    required this.progress,
    required this.hasRuns,
    required this.isSelected,
    required this.isToday,
    required this.day,
  });

  final double progress;
  final bool hasRuns;
  final bool isSelected;
  final bool isToday;
  final int day;

  @override
  Widget build(BuildContext context) {
    final ringColor = progress >= 1 ? AppColors.voltGreen : AppColors.cyan;
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: hasRuns ? progress : 0,
            strokeWidth: 3,
            backgroundColor: AppColors.chalk.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              hasRuns ? ringColor : AppColors.chalk.withValues(alpha: 0.12),
            ),
          ),
          Text(
            '$day',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected || isToday ? AppColors.chalk : AppColors.muted,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunCountBadge extends StatelessWidget {
  const _RunCountBadge({super.key, required this.runCount});

  final int runCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.voltGreen,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$runCount',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.black,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

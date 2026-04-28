import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class HistoryCalendarHeader extends StatelessWidget {
  const HistoryCalendarHeader({
    super.key,
    required this.focusedMonth,
    required this.isExpanded,
    required this.dayGoalM,
    required this.displaySettings,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onViewModeChanged,
  });

  final DateTime focusedMonth;
  final bool isExpanded;
  final double dayGoalM;
  final RunDisplaySettings displaySettings;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<bool> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final goalLabel = formatRunDistance(dayGoalM, displaySettings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('history-calendar-prev-button'),
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              color: AppColors.chalk,
            ),
            Expanded(
              child: Text(
                '${focusedMonth.year}년 ${focusedMonth.month}월',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              key: const Key('history-calendar-next-button'),
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              color: AppColors.chalk,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '하루 기준 $goalLabel',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ),
            _HistoryCalendarModeToggle(
              key: const Key('history-calendar-toggle-button'),
              isExpanded: isExpanded,
              onChanged: onViewModeChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryCalendarModeToggle extends StatelessWidget {
  const _HistoryCalendarModeToggle({
    super.key,
    required this.isExpanded,
    required this.onChanged,
  });

  final bool isExpanded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CalendarModeButton(
            key: const Key('history-calendar-week-button'),
            label: '주간',
            selected: !isExpanded,
            onPressed: () => onChanged(false),
          ),
          _CalendarModeButton(
            key: const Key('history-calendar-month-button'),
            label: '월간',
            selected: isExpanded,
            onPressed: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _CalendarModeButton extends StatelessWidget {
  const _CalendarModeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.voltGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected ? AppColors.black : AppColors.chalk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryWeekdayHeader extends StatelessWidget {
  const HistoryWeekdayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return Row(
      children: [
        for (final weekday in weekdays)
          Expanded(
            child: Text(
              weekday,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class HistoryCalendarClearButton extends StatelessWidget {
  const HistoryCalendarClearButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        key: const Key('history-calendar-clear-selection-button'),
        onPressed: onPressed,
        child: const Text('오늘 보기'),
      ),
    );
  }
}

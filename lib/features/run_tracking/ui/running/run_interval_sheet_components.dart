import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_interval_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet_buttons.dart';

class RunIntervalSheetHeader extends StatelessWidget {
  const RunIntervalSheetHeader({
    super.key,
    required this.workout,
    required this.onEnabledChanged,
  });

  final RunIntervalWorkout workout;
  final ValueChanged<bool> onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            key: const Key('run-interval-drag-handle'),
            width: 56,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('인터벌 설정', style: _titleStyle(context)),
                  const SizedBox(height: 8),
                  Text(
                    '질주와 휴식을 반복하는 간단한 러닝 훈련입니다.',
                    style: _bodyStyle(context, AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    runIntervalWorkoutSummary(workout),
                    key: const Key('run-interval-summary-label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _bodyStyle(context, AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              key: const Key('run-interval-enabled-switch'),
              value: workout.enabled,
              activeThumbColor: AppColors.voltGreen,
              activeTrackColor: AppColors.voltGreen.withValues(alpha: 0.32),
              inactiveThumbColor: AppColors.chalk,
              inactiveTrackColor: AppColors.graphite,
              onChanged: onEnabledChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class RunIntervalRepeatCard extends StatelessWidget {
  const RunIntervalRepeatCard({
    super.key,
    required this.repeatCount,
    required this.onChanged,
  });

  final int repeatCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _IntervalCard(
      title: '반복',
      value: '$repeatCount회',
      accent: AppColors.voltGreen,
      child: Row(
        children: [
          RunIntervalStepperButton(
            key: const Key('run-interval-repeat-decrement'),
            icon: Icons.remove,
            onPressed: () => onChanged((repeatCount - 1).clamp(1, 30)),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$repeatCount회',
                key: const Key('run-interval-repeat-count-label'),
                style: _valueStyle(context, AppColors.chalk),
              ),
            ),
          ),
          RunIntervalStepperButton(
            key: const Key('run-interval-repeat-increment'),
            icon: Icons.add,
            onPressed: () => onChanged((repeatCount + 1).clamp(1, 30)),
          ),
        ],
      ),
    );
  }
}

class _IntervalCard extends StatelessWidget {
  const _IntervalCard({
    required this.title,
    required this.value,
    required this.child,
    required this.accent,
  });

  final String title;
  final String value;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('run-interval-card-$title'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: _labelStyle(context))),
              Text(value, style: _valueStyle(context, accent)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppColors.panel,
    border: Border.all(color: AppColors.chalk, width: 2),
    borderRadius: BorderRadius.circular(8),
  );
}

TextStyle? _titleStyle(BuildContext context) {
  return Theme.of(context).textTheme.headlineSmall?.copyWith(
    color: AppColors.chalk,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}

TextStyle? _labelStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: AppColors.chalk,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}

TextStyle? _valueStyle(BuildContext context, Color color) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: color,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}

TextStyle? _bodyStyle(BuildContext context, Color color) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: color,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );
}

String runIntervalWorkoutSummary(RunIntervalWorkout workout) {
  final enabledLabel = workout.enabled ? 'ON' : 'OFF';
  final work = formatRunIntervalTarget(workout.work);
  final recovery = formatRunIntervalTarget(workout.recovery);
  return '$enabledLabel · 질주 $work · 휴식 $recovery · ${workout.repeatCount}회';
}

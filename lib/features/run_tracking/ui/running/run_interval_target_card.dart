import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_interval_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_direct_input.dart';

class RunIntervalTargetCard extends StatelessWidget {
  const RunIntervalTargetCard({
    super.key,
    required this.title,
    required this.target,
    required this.timeFallback,
    required this.distanceFallback,
    required this.onChanged,
    this.accent = AppColors.chalk,
  });

  final String title;
  final RunIntervalTarget target;
  final RunIntervalTarget timeFallback;
  final RunIntervalTarget distanceFallback;
  final ValueChanged<RunIntervalTarget> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDistance = target.type == RunIntervalTargetType.distance;
    final selectedTarget = _targetForMode(
      target,
      isDistance ? distanceFallback : timeFallback,
    );
    return _IntervalCard(
      title: title,
      value: formatRunIntervalTarget(selectedTarget),
      accent: accent,
      child: Column(
        children: [
          RunIntervalModeSelector(
            title: title,
            isDistance: isDistance,
            onTime: () => onChanged(timeFallback),
            onDistance: () => onChanged(distanceFallback),
          ),
          const SizedBox(height: 10),
          RunIntervalDirectTargetInput(
            title: title,
            target: selectedTarget,
            isDistance: isDistance,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class RunIntervalModeSelector extends StatelessWidget {
  const RunIntervalModeSelector({
    super.key,
    required this.title,
    required this.isDistance,
    required this.onTime,
    required this.onDistance,
  });

  final String title;
  final bool isDistance;
  final VoidCallback onTime;
  final VoidCallback onDistance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RunIntervalModeButton(
            key: Key('run-interval-$title-mode-time'),
            label: '시간',
            selected: !isDistance,
            onPressed: onTime,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RunIntervalModeButton(
            key: Key('run-interval-$title-mode-distance'),
            label: '거리',
            selected: isDistance,
            onPressed: onDistance,
          ),
        ),
      ],
    );
  }
}

class RunIntervalModeButton extends StatelessWidget {
  const RunIntervalModeButton({
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
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? AppColors.black : AppColors.chalk,
          backgroundColor: selected ? AppColors.voltGreen : AppColors.black,
          side: BorderSide(
            color: selected ? AppColors.voltGreen : AppColors.muted,
            width: 2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: EdgeInsets.zero,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
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
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
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

RunIntervalTarget _targetForMode(
  RunIntervalTarget target,
  RunIntervalTarget fallback,
) {
  return target.type == fallback.type ? target : fallback;
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

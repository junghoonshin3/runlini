import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunIntervalWarmCooldownCard extends StatelessWidget {
  const RunIntervalWarmCooldownCard({
    super.key,
    required this.warmupEnabled,
    required this.cooldownEnabled,
    required this.onWarmupChanged,
    required this.onCooldownChanged,
  });

  final bool warmupEnabled;
  final bool cooldownEnabled;
  final ValueChanged<bool> onWarmupChanged;
  final ValueChanged<bool> onCooldownChanged;

  @override
  Widget build(BuildContext context) {
    return _SimpleIntervalCard(
      title: '전후 준비',
      value: '5분',
      child: Column(
        children: [
          _IntervalSwitchRow(
            key: const Key('run-interval-warmup-row'),
            label: '워밍업 5분',
            value: warmupEnabled,
            switchKey: const Key('run-interval-warmup-toggle'),
            onChanged: onWarmupChanged,
          ),
          const Divider(color: AppColors.graphite, height: 18),
          _IntervalSwitchRow(
            key: const Key('run-interval-cooldown-row'),
            label: '쿨다운 5분',
            value: cooldownEnabled,
            switchKey: const Key('run-interval-cooldown-toggle'),
            onChanged: onCooldownChanged,
          ),
        ],
      ),
    );
  }
}

class _SimpleIntervalCard extends StatelessWidget {
  const _SimpleIntervalCard({
    required this.title,
    required this.value,
    required this.child,
  });

  final String title;
  final String value;
  final Widget child;

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
              Text(value, style: _valueStyle(context)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _IntervalSwitchRow extends StatelessWidget {
  const _IntervalSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.switchKey,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Key switchKey;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: _switchLabelStyle(context))),
        Switch(
          key: switchKey,
          value: value,
          activeThumbColor: AppColors.voltGreen,
          activeTrackColor: AppColors.voltGreen.withValues(alpha: 0.32),
          inactiveThumbColor: AppColors.chalk,
          inactiveTrackColor: AppColors.graphite,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

TextStyle? _labelStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: AppColors.chalk,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}

TextStyle? _valueStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.copyWith(
    color: AppColors.voltGreen,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}

TextStyle? _switchLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: AppColors.chalk,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}

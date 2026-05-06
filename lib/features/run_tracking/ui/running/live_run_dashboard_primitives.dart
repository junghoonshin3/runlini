import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class LiveDashboardCompactMetric extends StatelessWidget {
  const LiveDashboardCompactMetric({
    super.key,
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              key: valueKey,
              maxLines: 1,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.chalk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveDashboardLargeMetric extends StatelessWidget {
  const LiveDashboardLargeMetric({
    super.key,
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            key: valueKey,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.chalk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class LiveDashboardPausedPill extends StatelessWidget {
  const LiveDashboardPausedPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('live-run-paused-label'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.electricRed.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.electricRed, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PAUSED',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.electricRed,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class LiveDashboardDivider extends StatelessWidget {
  const LiveDashboardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.chalk.withValues(alpha: 0.18),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class HistoryNoRunsOnDatePanel extends StatelessWidget {
  const HistoryNoRunsOnDatePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '이 날은 저장된 러닝이 없어요.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
      ),
    );
  }
}

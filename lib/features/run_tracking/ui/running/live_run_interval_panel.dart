import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_interval_formatters.dart';

class LiveRunIntervalPanel extends StatelessWidget {
  const LiveRunIntervalPanel({
    super.key,
    required this.frame,
    required this.onAdvance,
  });

  final RunIntervalFrame frame;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final isOpen = frame.step.target.type == RunIntervalTargetType.open;
    return Container(
      key: const Key('live-run-interval-panel'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.88),
        border: Border.all(color: AppColors.voltGreen, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatRunIntervalStepLabel(frame.step),
                  key: const Key('live-run-interval-step-label'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.voltGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatRunIntervalRemaining(frame)} · 다음 ${formatRunIntervalShortStep(frame.nextStep)}',
                  key: const Key('live-run-interval-remaining-label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.chalk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (isOpen) ...[
            const SizedBox(width: 10),
            TextButton(
              key: const Key('live-run-interval-advance-button'),
              onPressed: onAdvance,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.black,
                backgroundColor: AppColors.voltGreen,
                minimumSize: const Size(58, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                '다음',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

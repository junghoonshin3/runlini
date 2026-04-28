import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_history_distance_summary.dart';
import 'package:runlini/features/run_tracking/types/run_history_period.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class HistoryDistanceRing extends StatelessWidget {
  const HistoryDistanceRing({
    super.key,
    required this.summary,
    required this.displaySettings,
  });

  final RunHistoryDistanceSummary summary;
  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    final distance = formatRunDistance(
      summary.distanceM,
      displaySettings,
      decimals: 2,
    );
    return SizedBox(
      key: const Key('history-distance-progress-ring'),
      width: 184,
      height: 184,
      child: CustomPaint(
        painter: _RingPainter(progress: summary.progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                summary.period.distanceLabel,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                distance,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.chalk,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(summary.progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: summary.hasExceededGoal
                      ? AppColors.voltGreen
                      : AppColors.amber,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 14.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.chalk.withValues(alpha: 0.12);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [AppColors.voltGreen, AppColors.amber, AppColors.cyan],
      ).createShader(circleRect);

    canvas.drawCircle(center, radius, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        circleRect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

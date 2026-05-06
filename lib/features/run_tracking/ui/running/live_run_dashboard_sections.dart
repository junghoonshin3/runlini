import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/ghost_racer/ui/ghost_race_formatters.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/live_run_metrics_formatters.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_interval_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_dashboard_primitives.dart';

class LiveRunDashboardCollapsed extends StatelessWidget {
  const LiveRunDashboardCollapsed({
    super.key,
    required this.metrics,
    required this.displaySettings,
  });

  final LiveRunMetrics metrics;
  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('live-run-dashboard-collapsed'),
      children: [
        if (metrics.isPaused) ...[
          const LiveDashboardPausedPill(),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: LiveDashboardCompactMetric(
            label: '거리',
            value: formatRunDistance(
              metrics.distanceKm * 1000,
              displaySettings,
              decimals: 2,
            ),
            valueKey: const Key('live-run-distance-value'),
          ),
        ),
        Expanded(
          child: LiveDashboardCompactMetric(
            label: '시간',
            value: formatLiveRunElapsed(metrics.elapsedMs),
            valueKey: const Key('live-run-elapsed-value'),
          ),
        ),
        Expanded(
          child: LiveDashboardCompactMetric(
            label: '평균 페이스',
            value: formatRunPace(metrics.averagePaceSecPerKm, displaySettings),
            valueKey: const Key('live-run-average-pace-value'),
          ),
        ),
      ],
    );
  }
}

class LiveRunDashboardExpanded extends StatelessWidget {
  const LiveRunDashboardExpanded({
    super.key,
    required this.metrics,
    required this.displaySettings,
    required this.onAdvanceInterval,
    this.ghostRace,
    this.intervalFrame,
  });

  final LiveRunMetrics metrics;
  final RunDisplaySettings displaySettings;
  final GhostRaceFrame? ghostRace;
  final RunIntervalFrame? intervalFrame;
  final VoidCallback onAdvanceInterval;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('live-run-dashboard-expanded'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (metrics.isPaused) ...[
          const LiveDashboardPausedPill(),
          const SizedBox(height: 10),
        ],
        if (intervalFrame != null) ...[
          _IntervalRow(frame: intervalFrame!, onAdvance: onAdvanceInterval),
          const LiveDashboardDivider(),
        ],
        Row(
          children: [
            Expanded(
              child: LiveDashboardLargeMetric(
                label: '거리',
                value: formatRunDistance(
                  metrics.distanceKm * 1000,
                  displaySettings,
                  decimals: 2,
                ),
                valueKey: const Key('live-run-distance-value-expanded'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LiveDashboardLargeMetric(
                label: '시간',
                value: formatLiveRunElapsed(metrics.elapsedMs),
                valueKey: const Key('live-run-elapsed-value-expanded'),
              ),
            ),
          ],
        ),
        const LiveDashboardDivider(),
        Row(
          children: [
            Expanded(
              child: LiveDashboardCompactMetric(
                label: '평균 페이스',
                value: formatRunPace(
                  metrics.averagePaceSecPerKm,
                  displaySettings,
                ),
                valueKey: const Key('live-run-average-pace-value-expanded'),
              ),
            ),
            Expanded(
              child: LiveDashboardCompactMetric(
                label: '평균 스피드',
                value: formatRunSpeed(metrics.averageSpeedKmh, displaySettings),
                valueKey: const Key('live-run-average-speed-value'),
              ),
            ),
            Expanded(
              child: LiveDashboardCompactMetric(
                label: '칼로리',
                value: formatLiveRunCalories(metrics.caloriesKcal),
                valueKey: const Key('live-run-calories-value'),
              ),
            ),
          ],
        ),
        if (ghostRace != null &&
            ghostRace!.status != GhostRaceStatus.unavailable) ...[
          const LiveDashboardDivider(),
          _GhostRow(frame: ghostRace!),
        ],
      ],
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({required this.frame, required this.onAdvance});

  final RunIntervalFrame frame;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final isOpen = frame.step.target.type == RunIntervalTargetType.open;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatRunIntervalStepLabel(frame.step),
                key: const Key('live-run-interval-step-label'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.voltGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${formatRunIntervalRemaining(frame)} · 다음 '
                '${formatRunIntervalShortStep(frame.nextStep)}',
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
              minimumSize: const Size(54, 34),
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
    );
  }
}

class _GhostRow extends StatelessWidget {
  const _GhostRow({required this.frame});

  final GhostRaceFrame frame;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(frame.status);
    return Row(
      key: const Key('ghost-race-panel'),
      children: [
        Container(width: 4, height: 44, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatGhostRaceStatus(frame.status),
                key: const Key('ghost-race-status-label'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                frame.isOffRoute
                    ? '고스트 비교를 잠시 멈췄어요'
                    : formatGhostRaceDistanceGap(frame.distanceGapM),
                key: const Key('ghost-race-distance-gap-value'),
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
        const SizedBox(width: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            frame.isOffRoute
                ? '--:--'
                : formatGhostRaceTimeGap(frame.timeGapMs),
            key: const Key('ghost-race-time-gap-value'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Color _colorFor(GhostRaceStatus status) {
    switch (status) {
      case GhostRaceStatus.ahead:
        return AppColors.voltGreen;
      case GhostRaceStatus.behind:
        return AppColors.electricRed;
      case GhostRaceStatus.level:
        return AppColors.chalk;
      case GhostRaceStatus.offRoute:
        return AppColors.orange;
      case GhostRaceStatus.unavailable:
        return AppColors.muted;
    }
  }
}

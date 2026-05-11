// 러닝 중 고스트런 상태와 격차를 표시하는 대시보드 섹션
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/ghost_racer/ui/ghost_race_formatters.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_dashboard_primitives.dart';

class LiveRunDashboardGhostCollapsed extends StatelessWidget {
  const LiveRunDashboardGhostCollapsed({super.key, required this.frame});

  final GhostRaceFrame frame;

  @override
  Widget build(BuildContext context) {
    final startPending = !frame.startConfirmed;
    final color = ghostDashboardColor(frame.status);
    return Row(
      key: const Key('live-run-ghost-collapsed'),
      children: [
        Container(width: 4, height: 34, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatGhostRaceStatus(frame.status),
                      key: const Key('live-run-ghost-status-collapsed'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (startPending) ...[
                    const SizedBox(width: 6),
                    const _GhostStartPendingBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                frame.isOffRoute
                    ? '경로 확인 중'
                    : formatGhostRaceTimeGap(frame.timeGapMs),
                key: const Key('live-run-ghost-gap-collapsed'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.chalk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LiveRunDashboardGhostExpanded extends StatelessWidget {
  const LiveRunDashboardGhostExpanded({
    super.key,
    required this.frame,
    required this.displaySettings,
  });

  final GhostRaceFrame frame;
  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    final startPending = !frame.startConfirmed;
    final color = ghostDashboardColor(frame.status);
    return Column(
      key: const Key('ghost-race-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 44, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatGhostRaceStatus(frame.status),
                          key: const Key('ghost-race-status-label'),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      if (startPending) const _GhostStartPendingBadge(),
                    ],
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
        ),
        const LiveDashboardDivider(),
        Row(
          children: [
            Expanded(
              child: LiveDashboardCompactMetric(
                label: '진행',
                value: '${(frame.routeProgress * 100).clamp(0, 100).round()}%',
                valueKey: const Key('ghost-race-progress-value'),
              ),
            ),
            Expanded(
              child: LiveDashboardCompactMetric(
                label: '남은 거리',
                value: frame.distanceToFinishM.isFinite
                    ? formatRunDistance(
                        frame.distanceToFinishM,
                        displaySettings,
                        decimals: 2,
                      )
                    : '--',
                valueKey: const Key('ghost-race-remaining-distance-value'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Color ghostDashboardColor(GhostRaceStatus status) {
  return switch (status) {
    GhostRaceStatus.ahead => AppColors.voltGreen,
    GhostRaceStatus.behind => AppColors.electricRed,
    GhostRaceStatus.level => AppColors.chalk,
    GhostRaceStatus.offRoute => AppColors.orange,
    GhostRaceStatus.unavailable => AppColors.muted,
  };
}

class _GhostStartPendingBadge extends StatelessWidget {
  const _GhostStartPendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ghost-start-pending-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '확인 중',
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.cyan,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

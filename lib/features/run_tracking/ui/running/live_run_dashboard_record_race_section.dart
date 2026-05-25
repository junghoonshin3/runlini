// 러닝 중 기록 레이스 상태와 격차를 표시하는 대시보드 섹션
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/record_race/ui/record_race_formatters.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_dashboard_primitives.dart';

class LiveRunDashboardRecordRaceCollapsed extends StatelessWidget {
  const LiveRunDashboardRecordRaceCollapsed({super.key, required this.frame});

  final RecordRaceFrame frame;

  @override
  Widget build(BuildContext context) {
    final startPending = !frame.startConfirmed;
    final color = recordRaceDashboardColor(frame.status);
    return Row(
      key: const Key('live-run-record-race-collapsed'),
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
                      formatRecordRaceStatus(frame.status),
                      key: const Key('live-run-record-race-status-collapsed'),
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
                    const _RecordRaceStartPendingBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                frame.isOffRoute
                    ? '경로 확인 중'
                    : formatRecordRaceTimeGap(frame.timeGapMs),
                key: const Key('live-run-record-race-gap-collapsed'),
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

class LiveRunDashboardRecordRaceExpanded extends StatelessWidget {
  const LiveRunDashboardRecordRaceExpanded({
    super.key,
    required this.frame,
    required this.displaySettings,
    this.completed = false,
  });

  final RecordRaceFrame frame;
  final RunDisplaySettings displaySettings;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final startPending = !frame.startConfirmed;
    final color = recordRaceDashboardColor(frame.status);
    return Column(
      key: const Key('record-race-panel'),
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
                          formatRecordRaceStatus(frame.status),
                          key: const Key('record-race-status-label'),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      if (startPending) const _RecordRaceStartPendingBadge(),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    frame.isOffRoute
                        ? '기록 레이스 비교를 잠시 멈췄어요'
                        : formatRecordRaceDistanceGap(frame.distanceGapM),
                    key: const Key('record-race-distance-gap-value'),
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
                    : formatRecordRaceTimeGap(frame.timeGapMs),
                key: const Key('record-race-time-gap-value'),
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
                value: _formatRecordRaceProgress(frame),
                valueKey: const Key('record-race-progress-value'),
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
                valueKey: const Key('record-race-remaining-distance-value'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Color recordRaceDashboardColor(RecordRaceStatus status) {
  return switch (status) {
    RecordRaceStatus.ahead => AppColors.voltGreen,
    RecordRaceStatus.behind => AppColors.electricRed,
    RecordRaceStatus.level => AppColors.chalk,
    RecordRaceStatus.offRoute => AppColors.orange,
    RecordRaceStatus.unavailable => AppColors.muted,
  };
}

String _formatRecordRaceProgress(RecordRaceFrame frame) {
  final percent = (frame.routeProgress * 100).clamp(0, 100).round();
  return '$percent%';
}

class _RecordRaceStartPendingBadge extends StatelessWidget {
  const _RecordRaceStartPendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('record-race-start-pending-badge'),
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

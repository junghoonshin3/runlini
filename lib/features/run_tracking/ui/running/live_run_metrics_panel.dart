import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/record_race/ui/record_race_formatters.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/live_run_metrics_formatters.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class LiveRunMetricsPanel extends StatelessWidget {
  const LiveRunMetricsPanel({
    super.key,
    required this.metrics,
    this.displaySettings = const RunDisplaySettings(),
    this.recordRace,
  });

  final LiveRunMetrics metrics;
  final RunDisplaySettings displaySettings;
  final RecordRaceFrame? recordRace;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('live-run-metrics-panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.86),
        border: Border.all(color: AppColors.chalk, width: 3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (metrics.isPaused) ...[
            Text(
              'PAUSED',
              key: const Key('live-run-paused-label'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.electricRed,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _PrimaryMetric(
            label: '거리',
            value: formatRunDistance(
              metrics.distanceKm * 1000,
              displaySettings,
              decimals: 2,
            ),
            valueKey: const Key('live-run-distance-value'),
          ),
          const SizedBox(height: 14),
          _PrimaryMetric(
            label: '시간',
            value: formatLiveRunElapsed(metrics.elapsedMs),
            valueKey: const Key('live-run-elapsed-value'),
          ),
          if (recordRace != null &&
              recordRace!.status != RecordRaceStatus.unavailable) ...[
            const SizedBox(height: 16),
            _RecordRaceMetric(frame: recordRace!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SecondaryMetric(
                  label: '평균 페이스',
                  value: formatRunPace(
                    metrics.averagePaceSecPerKm,
                    displaySettings,
                  ),
                  valueKey: const Key('live-run-average-pace-value'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryMetric(
                  label: '평균 스피드',
                  value: formatRunSpeed(
                    metrics.averageSpeedKmh,
                    displaySettings,
                  ),
                  valueKey: const Key('live-run-average-speed-value'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryMetric(
                  label: '칼로리',
                  value: formatLiveRunCalories(metrics.caloriesKcal),
                  valueKey: const Key('live-run-calories-value'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordRaceMetric extends StatelessWidget {
  const _RecordRaceMetric({required this.frame});

  final RecordRaceFrame frame;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(frame.status);
    return Container(
      key: const Key('record-race-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.graphite.withValues(alpha: 0.86),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatRecordRaceStatus(frame.status),
                  key: const Key('record-race-status-label'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  frame.isOffRoute
                      ? '기록 레이스 비교를 잠시 멈췄어요'
                      : formatRecordRaceDistanceGap(frame.distanceGapM),
                  key: const Key('record-race-distance-gap-value'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.chalk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            frame.isOffRoute
                ? '--:--'
                : formatRecordRaceTimeGap(frame.timeGapMs),
            key: const Key('record-race-time-gap-value'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(RecordRaceStatus status) {
    switch (status) {
      case RecordRaceStatus.ahead:
        return AppColors.voltGreen;
      case RecordRaceStatus.behind:
        return AppColors.electricRed;
      case RecordRaceStatus.level:
        return AppColors.chalk;
      case RecordRaceStatus.offRoute:
        return AppColors.orange;
      case RecordRaceStatus.unavailable:
        return AppColors.muted;
    }
  }
}

class _PrimaryMetric extends StatelessWidget {
  const _PrimaryMetric({
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            key: valueKey,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.chalk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryMetric extends StatelessWidget {
  const _SecondaryMetric({
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          key: valueKey,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.chalk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

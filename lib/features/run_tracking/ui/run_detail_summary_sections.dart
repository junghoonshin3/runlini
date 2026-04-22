import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/ui/live_run_metrics_formatters.dart';
import 'package:runlini/features/run_tracking/ui/run_detail_formatters.dart';

class RunDetailHeader extends StatelessWidget {
  const RunDetailHeader({
    super.key,
    required this.session,
    required this.detail,
  });

  final RunSession session;
  final RunSessionDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(AppColors.voltGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RUNLINI RECORD', style: _eyebrowStyle),
          const SizedBox(height: 10),
          const Text('Run Detail', style: _headlineStyle),
          const SizedBox(height: 14),
          Text(_dateLine(session), style: _mutedStyle),
          const SizedBox(height: 12),
          Text(
            '${detail.distanceKm.toStringAsFixed(2)} KM · '
            '${formatLiveRunElapsed(detail.durationMs)} · '
            'Pace ${_formatPaceValue(detail.averagePaceSecPerKm)}',
            style: _summaryStyle,
          ),
        ],
      ),
    );
  }

  String _dateLine(RunSession session) {
    final startedAt = session.startedAt;
    final hour = startedAt.hour.toString().padLeft(2, '0');
    final minute = startedAt.minute.toString().padLeft(2, '0');
    return '${startedAt.year}.${startedAt.month}.${startedAt.day} · '
        '$hour:$minute';
  }
}

class RunDetailMetricStrip extends StatelessWidget {
  const RunDetailMetricStrip({super.key, required this.detail});

  final RunSessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final metrics = <_MetricItem>[
      _MetricItem('Distance (KM)', detail.distanceKm.toStringAsFixed(2)),
      _MetricItem('Time', formatLiveRunElapsed(detail.durationMs)),
      _MetricItem(
        'Avg. Pace (KM)',
        _formatPaceValue(detail.averagePaceSecPerKm),
      ),
      _MetricItem(
        'Avg. Speed (KM/H)',
        detail.averageSpeedKmh.toStringAsFixed(1),
      ),
      _MetricItem(
        'Calories (KCAL)',
        detail.caloriesLabel.replaceAll(' kcal', ''),
      ),
      _MetricItem(
        'Elevation (M)',
        detail.elevationGainM == null
            ? '--'
            : detail.elevationGainM!.round().toString(),
      ),
      _MetricItem(
        'Heart Rate (BPM)',
        detail.averageHeartRateBpm?.toString() ?? '--',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map((metric) => _MetricTile(width: itemWidth, metric: metric))
              .toList(growable: false),
        );
      },
    );
  }
}

String _formatPaceValue(double? secondsPerKm) {
  return formatRunDetailPaceCompact(secondsPerKm ?? 0).replaceFirst('/KM', '');
}

class RunDetailGhostComparison extends StatelessWidget {
  const RunDetailGhostComparison({super.key, required this.summary});

  final RunSessionGhostSummary summary;

  @override
  Widget build(BuildContext context) {
    final accent = switch (summary.result) {
      RunSessionGhostResult.ahead => AppColors.voltGreen,
      RunSessionGhostResult.behind => AppColors.electricRed,
      RunSessionGhostResult.level => AppColors.chalk,
      RunSessionGhostResult.offRoute => AppColors.orange,
    };

    return Container(
      key: const Key('detail-ghost-compare'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ghost Compare', style: _titleStyle.copyWith(color: accent)),
          const SizedBox(height: 10),
          Text(_resultLabel(summary), style: _headlineSmallStyle),
          const SizedBox(height: 10),
          Text('vs ${summary.ghostLabel}', style: _mutedStyle),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _GhostChip(
                label: 'Time Gap',
                value: _formatGap(summary.timeGapMs),
              ),
              _GhostChip(
                label: 'Distance Gap',
                value: '${summary.distanceGapM.abs().round()} M',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resultLabel(RunSessionGhostSummary summary) {
    return switch (summary.result) {
      RunSessionGhostResult.ahead => 'You beat the ghost',
      RunSessionGhostResult.behind => 'Ghost finished ahead',
      RunSessionGhostResult.level => 'Matched the ghost',
      RunSessionGhostResult.offRoute => '경로 이탈',
    };
  }

  String _formatGap(int timeGapMs) {
    final sign = timeGapMs > 0
        ? '+'
        : timeGapMs < 0
        ? '-'
        : '';
    final seconds = timeGapMs.abs() ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$sign$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.width, required this.metric});

  final double width;
  final _MetricItem metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(AppColors.chalk),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: _mutedStyle),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(metric.value, maxLines: 1, style: _valueStyle),
          ),
        ],
      ),
    );
  }
}

class _GhostChip extends StatelessWidget {
  const _GhostChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label · $value', style: _summaryStyle),
    );
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value);

  final String label;
  final String value;
}

BoxDecoration _panelDecoration(Color accent) {
  return BoxDecoration(
    color: AppColors.panel,
    border: Border.all(color: accent.withValues(alpha: 0.22)),
    borderRadius: BorderRadius.circular(8),
  );
}

const _eyebrowStyle = TextStyle(
  color: AppColors.voltGreen,
  fontSize: 12,
  fontWeight: FontWeight.w900,
);
const _headlineStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 32,
  fontWeight: FontWeight.w900,
);
const _headlineSmallStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 20,
  fontWeight: FontWeight.w900,
);
const _titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w900);
const _valueStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 24,
  fontWeight: FontWeight.w900,
);
const _summaryStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);
const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);

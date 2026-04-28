import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_chart_bounds.dart';
import 'package:runlini/features/run_tracking/ui/formatters/live_run_metrics_formatters.dart';

class RunDetailLineChart extends StatelessWidget {
  const RunDetailLineChart({
    super.key,
    required this.title,
    required this.samples,
    required this.color,
    required this.emptyLabel,
    required this.durationMs,
    required this.valueFormatter,
    required this.summaryFormatter,
    this.note,
  });

  final String title;
  final List<RunMetricSample> samples;
  final Color color;
  final String emptyLabel;
  final int durationMs;
  final String Function(double value) valueFormatter;
  final String Function(double average, double min, double max)
  summaryFormatter;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final validSamples = samples
        .where((sample) => sample.value.isFinite)
        .toList(growable: false);
    if (validSamples.isEmpty) {
      return _EmptyChart(title: title, label: emptyLabel);
    }

    final values = validSamples.map((sample) => sample.value).toList();
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final average =
        values.reduce((left, right) => left + right) / values.length;
    final yBounds = ChartBounds.from(min: min, max: max);
    final maxXSeconds = math.max(
      1.0,
      math.max(durationMs, validSamples.last.elapsedMs) / 1000,
    );
    final spots = validSamples
        .map((sample) => FlSpot(sample.elapsedMs / 1000, sample.value))
        .toList(growable: false);

    return Container(
      key: Key('detail-chart-${title.split(' (').first.toLowerCase()}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(
            title: title,
            summary: summaryFormatter(average, min, max),
            note: note,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 174,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxXSeconds,
                minY: yBounds.min,
                maxY: yBounds.max,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.chalk.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: _titles(maxXSeconds, valueFormatter),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: average,
                      color: AppColors.chalk.withValues(alpha: 0.32),
                      strokeWidth: 1,
                      dashArray: const [6, 6],
                    ),
                  ],
                ),
                lineTouchData: _touchData(
                  valueFormatter: valueFormatter,
                  color: color,
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: color,
                    barWidth: 4,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    isStrokeCapRound: true,
                    isStrokeJoinRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  FlTitlesData _titles(
    double maxXSeconds,
    String Function(double value) valueFormatter,
  ) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: math.max(1, maxXSeconds / 2),
          getTitlesWidget: (value, meta) {
            if (!_isEdgeValue(value, 0, maxXSeconds)) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              child: Text(
                formatLiveRunElapsed((value * 1000).round()),
                style: _axisStyle,
              ),
            );
          },
        ),
      ),
    );
  }

  LineTouchData _touchData({
    required String Function(double value) valueFormatter,
    required Color color,
  }) {
    return LineTouchData(
      touchSpotThreshold: 18,
      getTouchedSpotIndicator: (barData, spotIndexes) {
        return spotIndexes
            .map(
              (_) => TouchedSpotIndicatorData(
                const FlLine(color: Colors.transparent, strokeWidth: 0),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 7,
                      color: color,
                      strokeColor: AppColors.chalk,
                      strokeWidth: 3,
                    );
                  },
                ),
              ),
            )
            .toList(growable: false);
      },
      touchTooltipData: LineTouchTooltipData(
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        maxContentWidth: 150,
        getTooltipColor: (_) => AppColors.graphite,
        getTooltipItems: (spots) {
          return spots
              .map((spot) {
                final elapsed = formatLiveRunElapsed((spot.x * 1000).round());
                return LineTooltipItem(
                  '$elapsed\n${valueFormatter(spot.y)}',
                  const TextStyle(
                    color: AppColors.chalk,
                    fontWeight: FontWeight.w900,
                  ),
                );
              })
              .toList(growable: false);
        },
      ),
    );
  }

  bool _isEdgeValue(double value, double min, double max) {
    final tolerance = math.max(0.01, (max - min).abs() * 0.02);
    return (value - min).abs() <= tolerance || (value - max).abs() <= tolerance;
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({required this.title, required this.summary, this.note});

  final String title;
  final String summary;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _titleStyle),
        const SizedBox(height: 8),
        Text(summary, style: _summaryStyle),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(note!, style: _noteStyle),
        ],
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.title, required this.label});

  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('detail-chart-empty-${title.split(' (').first.toLowerCase()}'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle),
          const SizedBox(height: 12),
          Text(label, style: _summaryStyle),
        ],
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 22,
  fontWeight: FontWeight.w900,
);
const _summaryStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);
const _noteStyle = TextStyle(
  color: AppColors.cyan,
  fontSize: 12,
  fontWeight: FontWeight.w800,
);
const _axisStyle = TextStyle(
  color: AppColors.muted,
  fontSize: 10,
  fontWeight: FontWeight.w800,
);

// 기록 상세 metric 막대그래프를 렌더링하는 위젯
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_chart_bounds.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_chart_frame.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_chart_haptic_layer.dart';
import 'package:runlini/features/run_tracking/ui/formatters/live_run_metrics_formatters.dart';

class RunDetailBarChart extends StatefulWidget {
  const RunDetailBarChart({
    super.key,
    required this.title,
    required this.samples,
    required this.color,
    required this.emptyLabel,
    required this.durationMs,
    required this.valueFormatter,
    required this.summaryFormatter,
    this.note,
    this.summaryAverageValue,
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
  final double? summaryAverageValue;

  @override
  State<RunDetailBarChart> createState() => _RunDetailBarChartState();
}

class _RunDetailBarChartState extends State<RunDetailBarChart> {
  int? _selectedBarIndex;

  @override
  Widget build(BuildContext context) {
    final validSamples = widget.samples
        .where((sample) => _isRenderableValue(sample.value))
        .toList(growable: false);
    if (validSamples.isEmpty) {
      return RunDetailEmptyChart(title: widget.title, label: widget.emptyLabel);
    }

    final values = validSamples.map((sample) => sample.value).toList();
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final average =
        values.reduce((left, right) => left + right) / values.length;
    final summaryAverage =
        widget.summaryAverageValue != null &&
            _isRenderableValue(widget.summaryAverageValue!)
        ? widget.summaryAverageValue!
        : average;
    final yBounds = ChartBounds.from(
      min: math.min(min, summaryAverage),
      max: math.max(max, summaryAverage),
    );
    final buckets = _buildBuckets(validSamples);

    return Container(
      key: Key('detail-chart-${widget.title.split(' (').first.toLowerCase()}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RunDetailChartHeader(
            title: widget.title,
            summary: widget.summaryFormatter(summaryAverage, min, max),
            note: widget.note,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 174,
            child: RunDetailChartHapticLayer(
              bucketCount: buckets.length,
              onSelected: _emitSelectionHaptic,
              onReset: _resetSelection,
              child: BarChart(
                BarChartData(
                  minY: yBounds.min,
                  maxY: yBounds.max,
                  alignment: BarChartAlignment.spaceBetween,
                  groupsSpace: 3,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.chalk.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _titles(buckets),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: summaryAverage,
                        color: AppColors.chalk.withValues(alpha: 0.32),
                        strokeWidth: 1,
                        dashArray: const [6, 6],
                      ),
                    ],
                  ),
                  barTouchData: _touchData(buckets),
                  barGroups: [
                    for (var index = 0; index < buckets.length; index++)
                      _barGroup(index, buckets[index], yBounds.min),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int index, _ChartBucket bucket, double fromY) {
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          fromY: fromY,
          toY: bucket.value,
          width: 5,
          color: widget.color.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  BarTouchData _touchData(List<_ChartBucket> buckets) {
    return BarTouchData(
      touchExtraThreshold: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 14,
      ),
      touchTooltipData: BarTouchTooltipData(
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        maxContentWidth: 150,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        getTooltipColor: (_) => AppColors.graphite,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final index = group.x.clamp(0, buckets.length - 1).toInt();
          final bucket = buckets[index];
          final elapsed = formatLiveRunElapsed(bucket.elapsedMs);
          return BarTooltipItem(
            '$elapsed\n${widget.valueFormatter(rod.toY)}',
            const TextStyle(
              color: AppColors.chalk,
              fontWeight: FontWeight.w900,
            ),
          );
        },
      ),
    );
  }

  void _emitSelectionHaptic(int nextIndex) {
    if (_selectedBarIndex == nextIndex) {
      return;
    }
    _selectedBarIndex = nextIndex;
    _playSelectionHaptic();
  }

  void _resetSelection() {
    _selectedBarIndex = null;
  }

  void _playSelectionHaptic() {
    HapticFeedback.lightImpact().catchError((Object error) {
      if (kDebugMode) {
        debugPrint('RunDetailBarChart haptic failed: $error');
      }
    });
  }

  FlTitlesData _titles(List<_ChartBucket> buckets) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: math.max(1, buckets.length - 1).toDouble(),
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (index < 0 ||
                index >= buckets.length ||
                (index != 0 && index != buckets.length - 1)) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              child: Text(
                formatLiveRunElapsed(buckets[index].elapsedMs),
                style: runDetailChartAxisStyle,
              ),
            );
          },
        ),
      ),
    );
  }

  List<_ChartBucket> _buildBuckets(List<RunMetricSample> samples) {
    const maxBarCount = 48;
    if (samples.length <= maxBarCount) {
      return [
        for (final sample in samples)
          _ChartBucket(elapsedMs: sample.elapsedMs, value: sample.value),
      ];
    }
    final bucketSize = (samples.length / maxBarCount).ceil();
    final buckets = <_ChartBucket>[];
    for (var start = 0; start < samples.length; start += bucketSize) {
      final end = math.min(samples.length, start + bucketSize);
      final slice = samples.sublist(start, end);
      final value =
          slice.fold<double>(0, (sum, sample) => sum + sample.value) /
          slice.length;
      final elapsedMs =
          slice.fold<int>(0, (sum, sample) => sum + sample.elapsedMs) ~/
          slice.length;
      buckets.add(_ChartBucket(elapsedMs: elapsedMs, value: value));
    }
    return buckets;
  }

  bool _isRenderableValue(double value) {
    return value.isFinite && value.abs() <= 1000000000000;
  }
}

class _ChartBucket {
  const _ChartBucket({required this.elapsedMs, required this.value});

  final int elapsedMs;
  final double value;
}

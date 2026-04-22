import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/run_session_detail_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/run_detail_formatters.dart';
import 'package:runlini/features/run_tracking/ui/run_detail_line_chart.dart';
import 'package:runlini/features/run_tracking/ui/run_detail_route_preview.dart';
import 'package:runlini/features/run_tracking/ui/run_detail_splits_table.dart';
import 'package:runlini/features/run_tracking/ui/run_detail_summary_sections.dart';
import 'package:runlini/features/run_tracking/ui/run_finish_review_actions.dart';
import 'package:runlini/features/run_tracking/ui/run_review_chrome.dart';

class RunFinishReviewPanel extends StatelessWidget {
  const RunFinishReviewPanel({
    super.key,
    required this.session,
    this.onSave,
    this.onDiscard,
    this.onClose,
    this.onMore,
  });

  final RunSession session;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;
  final VoidCallback? onClose;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final detail = const RunSessionDetailCalculator().calculate(session);
    return Container(
      key: const Key('run-finish-review-panel'),
      color: AppColors.black.withValues(alpha: 0.96),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width - 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RunReviewChrome(onClose: onClose, onMore: onMore),
                      const SizedBox(height: 18),
                      RunDetailHeader(session: session, detail: detail),
                      const SizedBox(height: 14),
                      RunDetailMetricStrip(detail: detail),
                      if (session.ghostSummary != null) ...[
                        const SizedBox(height: 14),
                        RunDetailGhostComparison(
                          summary: session.ghostSummary!,
                        ),
                      ],
                      const SizedBox(height: 28),
                      const _SectionTitle('Route'),
                      const SizedBox(height: 12),
                      RunDetailRoutePreview(points: session.points),
                      const SizedBox(height: 38),
                      RunDetailLineChart(
                        title: 'Pace',
                        samples: detail.paceSamplesSecPerKm,
                        color: AppColors.cyan,
                        emptyLabel: '페이스 데이터가 아직 없어요.',
                        durationMs: detail.durationMs,
                        note: '낮을수록 빠른 페이스',
                        valueFormatter: _formatPaceValue,
                        summaryFormatter: (average, min, max) =>
                            'Avg ${_formatPaceValue(average)} · '
                            '${_formatPaceValue(min)}-${_formatPaceValue(max)}',
                      ),
                      const SizedBox(height: 18),
                      RunDetailLineChart(
                        title: 'Speed',
                        samples: detail.speedSamplesKmh,
                        color: AppColors.cyan,
                        emptyLabel: '스피드 데이터가 아직 없어요.',
                        durationMs: detail.durationMs,
                        valueFormatter: (value) =>
                            '${value.toStringAsFixed(1)} KM/H',
                        summaryFormatter: (average, min, max) =>
                            'Avg ${average.toStringAsFixed(1)} KM/H · '
                            '${min.toStringAsFixed(1)}-'
                            '${max.toStringAsFixed(1)} KM/H',
                      ),
                      const SizedBox(height: 18),
                      RunDetailLineChart(
                        title: 'Elevation',
                        samples: detail.elevationSamplesM,
                        color: AppColors.voltGreen,
                        emptyLabel: '고도 데이터가 아직 없어요.',
                        durationMs: detail.durationMs,
                        valueFormatter: (value) =>
                            '${value.toStringAsFixed(1)} M',
                        summaryFormatter: (average, min, max) =>
                            'Avg ${average.toStringAsFixed(1)} M · '
                            '${min.toStringAsFixed(1)}-'
                            '${max.toStringAsFixed(1)} M',
                      ),
                      const SizedBox(height: 38),
                      RunDetailSplitsTable(splits: detail.splits),
                      const SizedBox(height: 18),
                      RunDetailLineChart(
                        title: 'Heart Rate',
                        samples: detail.heartRateSamplesBpm,
                        color: AppColors.orange,
                        emptyLabel: '심박 데이터가 아직 없어요.',
                        durationMs: detail.durationMs,
                        valueFormatter: (value) => '${value.round()} BPM',
                        summaryFormatter: (average, min, max) =>
                            'Avg ${average.round()} BPM · '
                            '${min.round()}-${max.round()} BPM',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onSave != null && onDiscard != null)
              RunFinishReviewActions(onSave: onSave!, onDiscard: onDiscard!),
          ],
        ),
      ),
    );
  }
}

String _formatPaceValue(double secondsPerKm) {
  return formatRunDetailPaceCompact(secondsPerKm).replaceFirst('/KM', '');
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.chalk,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

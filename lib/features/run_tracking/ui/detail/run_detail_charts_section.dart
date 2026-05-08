import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_bar_chart.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_splits_table.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class RunDetailChartsSection extends StatelessWidget {
  const RunDetailChartsSection({
    super.key,
    required this.detail,
    required this.displaySettings,
    required this.privacySettings,
  });

  final RunSessionDetail detail;
  final RunDisplaySettings displaySettings;
  final RunPrivacySettings privacySettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RunDetailBarChart(
          title: 'Pace (${paceUnitLabel(displaySettings)})',
          samples: detail.paceSamplesSecPerKm,
          color: AppColors.cyan,
          emptyLabel: '페이스 데이터가 아직 없어요.',
          durationMs: detail.durationMs,
          note: '낮을수록 빠른 페이스',
          summaryAverageValue: detail.averagePaceSecPerKm,
          valueFormatter: (value) => formatRunPace(value, displaySettings),
          summaryFormatter: (average, min, max) =>
              'Avg ${formatRunPace(average, displaySettings)} · '
              '${formatRunPace(min, displaySettings)}-'
              '${formatRunPace(max, displaySettings)}',
        ),
        const SizedBox(height: 18),
        RunDetailBarChart(
          title: 'Speed',
          samples: detail.speedSamplesKmh,
          color: AppColors.cyan,
          emptyLabel: '스피드 데이터가 아직 없어요.',
          durationMs: detail.durationMs,
          valueFormatter: (value) => formatRunSpeed(value, displaySettings),
          summaryFormatter: (average, min, max) =>
              'Avg ${formatRunSpeed(average, displaySettings)} · '
              '${formatRunSpeed(min, displaySettings)}-'
              '${formatRunSpeed(max, displaySettings)}',
        ),
        const SizedBox(height: 18),
        RunDetailBarChart(
          title: 'Elevation',
          samples: detail.elevationSamplesM,
          color: AppColors.voltGreen,
          emptyLabel: '고도 데이터가 아직 없어요.',
          durationMs: detail.durationMs,
          valueFormatter: (value) => '${value.toStringAsFixed(1)} m',
          summaryFormatter: (average, min, max) =>
              'Avg ${average.toStringAsFixed(1)} m · '
              '${min.toStringAsFixed(1)}-${max.toStringAsFixed(1)} m',
        ),
        const SizedBox(height: 38),
        RunDetailSplitsTable(
          splits: detail.splits,
          displaySettings: displaySettings,
          privacySettings: privacySettings,
        ),
        const SizedBox(height: 18),
        if (privacySettings.hideHeartRate)
          const _HiddenDataPanel(label: 'Heart Rate Hidden')
        else
          RunDetailBarChart(
            title: 'Heart Rate',
            samples: detail.heartRateSamplesBpm,
            color: AppColors.orange,
            emptyLabel: '심박 데이터가 아직 없어요.',
            durationMs: detail.durationMs,
            valueFormatter: (value) => '${value.round()} bpm',
            summaryFormatter: (average, min, max) =>
                'Avg ${average.round()} bpm · '
                '${min.round()}-${max.round()} bpm',
          ),
        const SizedBox(height: 18),
        RunDetailBarChart(
          title: 'Cadence',
          samples: detail.cadenceSamplesSpm,
          color: AppColors.amber,
          emptyLabel: '케이던스 데이터가 아직 없어요.',
          durationMs: detail.durationMs,
          valueFormatter: (value) => '${value.round()} spm',
          summaryFormatter: (average, min, max) =>
              'Avg ${average.round()} spm · '
              '${min.round()}-${max.round()} spm',
        ),
      ],
    );
  }
}

class _HiddenDataPanel extends StatelessWidget {
  const _HiddenDataPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: _mutedTextStyle),
    );
  }
}

const _mutedTextStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w900,
);

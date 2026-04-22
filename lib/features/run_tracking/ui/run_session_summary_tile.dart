import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

class RunSessionSummaryTile extends StatelessWidget {
  const RunSessionSummaryTile({super.key, required this.summary, this.onTap});

  final RunSessionSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk, width: 3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatRunDate(summary.startedAt),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: '거리',
                  value: formatDistance(summary.distanceM),
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: '시간',
                  value: formatDuration(summary.durationMs),
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: '평균 페이스',
                  value: formatPace(summary.averagePaceSecPerKm),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: content,
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

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
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

String formatRunDate(DateTime startedAt) {
  return '${startedAt.year}.${_twoDigits(startedAt.month)}.'
      '${_twoDigits(startedAt.day)} '
      '${_twoDigits(startedAt.hour)}:${_twoDigits(startedAt.minute)}';
}

String formatDistance(double distanceM) {
  return '${(distanceM / 1000).toStringAsFixed(1)} km';
}

String formatDuration(int durationMs) {
  final totalSeconds = durationMs ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }

  return '$minutes:${_twoDigits(seconds)}';
}

String formatPace(double secondsPerKm) {
  final rounded = secondsPerKm.round();
  final minutes = rounded ~/ 60;
  final seconds = rounded % 60;
  return '$minutes:${_twoDigits(seconds)} /km';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

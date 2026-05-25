import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/live_run_metrics_formatters.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

part 'run_detail_metric_strip.dart';

class RunDetailHeader extends StatelessWidget {
  const RunDetailHeader({
    super.key,
    required this.session,
    required this.detail,
    this.displaySettings = const RunDisplaySettings(),
    this.showSummaryChips = true,
  });

  final RunSession session;
  final RunSessionDetail detail;
  final RunDisplaySettings displaySettings;
  final bool showSummaryChips;

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
          if (showSummaryChips) ...[
            const SizedBox(height: 12),
            Wrap(
              key: const Key('run-detail-header-summary'),
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeaderSummaryChip(
                  label: 'Distance (${distanceUnitLabel(displaySettings)})',
                  value: _formatDistanceValue(
                    detail.distanceKm * 1000,
                    displaySettings,
                  ),
                ),
                _HeaderSummaryChip(
                  label: 'Time',
                  value: formatLiveRunElapsed(detail.durationMs),
                ),
                _HeaderSummaryChip(
                  label: 'Pace (${paceUnitLabel(displaySettings)})',
                  value: _formatPaceValue(
                    detail.averagePaceSecPerKm,
                    displaySettings,
                  ),
                ),
              ],
            ),
          ],
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

class _HeaderSummaryChip extends StatelessWidget {
  const _HeaderSummaryChip({required this.label, required this.value});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: _chipLabelStyle),
          const SizedBox(height: 4),
          Text(value, style: _chipValueStyle),
        ],
      ),
    );
  }
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
const _valueStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 24,
  fontWeight: FontWeight.w900,
);
const _chipLabelStyle = TextStyle(
  color: AppColors.muted,
  fontSize: 11,
  fontWeight: FontWeight.w900,
);
const _chipValueStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 16,
  fontWeight: FontWeight.w900,
);
const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);

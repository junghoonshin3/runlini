import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class RunDetailGhostComparison extends StatelessWidget {
  const RunDetailGhostComparison({
    super.key,
    required this.summary,
    this.displaySettings = const RunDisplaySettings(),
  });

  final RunSessionGhostSummary summary;
  final RunDisplaySettings displaySettings;

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
          Text(_resultLabel(summary), style: _headlineStyle),
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
                value: formatRunDistanceGap(
                  summary.distanceGapM,
                  displaySettings,
                ),
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

BoxDecoration _panelDecoration(Color accent) {
  return BoxDecoration(
    color: AppColors.panel,
    border: Border.all(color: accent.withValues(alpha: 0.22)),
    borderRadius: BorderRadius.circular(8),
  );
}

const _headlineStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 20,
  fontWeight: FontWeight.w900,
);
const _titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w900);
const _summaryStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);
const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);

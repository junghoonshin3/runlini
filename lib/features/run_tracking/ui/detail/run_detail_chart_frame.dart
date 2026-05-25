// 기록 상세 차트 공통 프레임 UI를 제공하는 위젯
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunDetailChartHeader extends StatelessWidget {
  const RunDetailChartHeader({
    super.key,
    required this.title,
    required this.summary,
    this.note,
  });

  final String title;
  final String summary;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: runDetailChartTitleStyle),
        const SizedBox(height: 8),
        Text(summary, style: runDetailChartSummaryStyle),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(note!, style: runDetailChartNoteStyle),
        ],
      ],
    );
  }
}

class RunDetailEmptyChart extends StatelessWidget {
  const RunDetailEmptyChart({
    super.key,
    required this.title,
    required this.label,
  });

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
          Text(title, style: runDetailChartTitleStyle),
          const SizedBox(height: 12),
          Text(label, style: runDetailChartSummaryStyle),
        ],
      ),
    );
  }
}

const runDetailChartTitleStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 22,
  fontWeight: FontWeight.w900,
);
const runDetailChartSummaryStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);
const runDetailChartNoteStyle = TextStyle(
  color: AppColors.cyan,
  fontSize: 12,
  fontWeight: FontWeight.w800,
);
const runDetailChartAxisStyle = TextStyle(
  color: AppColors.muted,
  fontSize: 10,
  fontWeight: FontWeight.w800,
);

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/run_ghost_comparison_builder.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_ghost_comparison_presenter.dart';

class RunDetailGhostComparison extends StatelessWidget {
  const RunDetailGhostComparison({
    super.key,
    required this.session,
    required this.summary,
    this.ghostSession,
    this.displaySettings = const RunDisplaySettings(),
    this.builder = const RunGhostComparisonBuilder(),
  });

  final RunSession session;
  final RunSessionGhostSummary summary;
  final RunSession? ghostSession;
  final RunDisplaySettings displaySettings;
  final RunGhostComparisonBuilder builder;

  @override
  Widget build(BuildContext context) {
    final comparison = builder.build(
      currentSession: session,
      summary: summary,
      ghostSession: ghostSession,
    );
    final presenter = RunDetailGhostComparisonPresenter(
      displaySettings: displaySettings,
    );
    final accent = presenter.accentFor(summary.result);
    final rows = presenter.rowsFor(comparison);

    return Container(
      key: const Key('detail-ghost-compare'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('고스트 비교', style: _titleStyle.copyWith(color: accent)),
          const SizedBox(height: 10),
          Text(presenter.heroLabel(summary), style: _headlineStyle),
          const SizedBox(height: 8),
          Text(
            'vs ${summary.ghostLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _mutedStyle,
          ),
          const SizedBox(height: 16),
          const _ComparisonHeader(),
          const SizedBox(height: 4),
          for (final row in rows) ...[
            _ComparisonRow(row: row),
            if (row != rows.last) const _Divider(),
          ],
        ],
      ),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 7, child: Text('항목', style: _captionStyle)),
        Expanded(flex: 6, child: Text('내 기록', style: _captionStyle)),
        Expanded(flex: 6, child: Text('고스트', style: _captionStyle)),
        Expanded(flex: 6, child: Text('차이', style: _captionStyle)),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.row});

  final RunDetailGhostComparisonRowData row;

  @override
  Widget build(BuildContext context) {
    final deltaColor = switch (row.tone) {
      RunDetailGhostComparisonTone.improved => AppColors.voltGreen,
      RunDetailGhostComparisonTone.worsened => AppColors.electricRed,
      RunDetailGhostComparisonTone.neutral => AppColors.chalk,
      RunDetailGhostComparisonTone.muted => AppColors.muted,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 7, child: Text(row.label, style: _rowLabelStyle)),
          Expanded(flex: 6, child: _Cell(row.current)),
          Expanded(flex: 6, child: _Cell(row.ghost)),
          Expanded(
            flex: 6,
            child: _Cell(row.delta, color: deltaColor, strong: true),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.value, {this.color = AppColors.chalk, this.strong = false});

  final String value;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.chalk.withValues(alpha: 0.08));
  }
}

BoxDecoration _panelDecoration(Color accent) {
  return BoxDecoration(
    color: AppColors.panel,
    border: Border.all(color: accent.withValues(alpha: 0.36)),
    borderRadius: BorderRadius.circular(8),
  );
}

const _headlineStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 24,
  fontWeight: FontWeight.w900,
);
const _titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w900);
const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);
const _captionStyle = TextStyle(
  color: AppColors.muted,
  fontSize: 11,
  fontWeight: FontWeight.w900,
);
const _rowLabelStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 12,
  fontWeight: FontWeight.w900,
);

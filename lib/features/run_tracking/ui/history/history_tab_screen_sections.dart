// 기록 탭의 헤더, 복구 패널, 리스트 라벨 섹션을 렌더링한다
part of 'history_tab_screen.dart';

String _selectedDateLabel(DateTime date) {
  return '${date.month}월 ${date.day}일 기록';
}

List<Widget> _withHistorySpacing(List<Widget> children) {
  return [
    for (var index = 0; index < children.length; index += 1) ...[
      if (index > 0) const SizedBox(height: 12),
      children[index],
    ],
  ];
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.todayDistanceM,
    required this.todayRunCount,
    required this.displaySettings,
  });

  final double todayDistanceM;
  final int todayRunCount;
  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 340;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기록',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              '오늘 기록과 목표를 바로 확인합니다.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        );
        final summary = _TodaySummaryBadge(
          distanceM: todayDistanceM,
          runCount: todayRunCount,
          displaySettings: displaySettings,
          expand: compact,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: summary),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 14),
            summary,
          ],
        );
      },
    );
  }
}

class _TodaySummaryBadge extends StatelessWidget {
  const _TodaySummaryBadge({
    required this.distanceM,
    required this.runCount,
    required this.displaySettings,
    required this.expand,
  });

  final double distanceM;
  final int runCount;
  final RunDisplaySettings displaySettings;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final distance = formatRunDistance(distanceM, displaySettings);
    return Container(
      key: const Key('history-today-summary-badge'),
      width: expand ? double.infinity : 116,
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '오늘',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cyan,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              distance,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.chalk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$runCount회',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _HistoryRecoveryPanel extends StatelessWidget {
  const _HistoryRecoveryPanel({
    required this.isBusy,
    required this.onRestoreFromHealth,
  });

  final bool isBusy;
  final VoidCallback onRestoreFromHealth;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('health-restore-empty-panel'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.voltGreen.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('저장된 기록이 없어요', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '앱을 다시 설치했거나 데이터가 비어 있다면 Health Connect에서 최근 기록을 복구할 수 있어요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 220.0;
              final buttonWidth = availableWidth < 220 ? availableWidth : 220.0;

              return SizedBox(
                width: buttonWidth,
                child: OutlinedButton(
                  key: const Key('health-restore-settings-button'),
                  onPressed: isBusy ? null : onRestoreFromHealth,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isBusy ? '처리 중...' : 'Health 기록 가져오기',
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryListLabel extends StatelessWidget {
  const _HistoryListLabel({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Text(
      _selectedDateLabel(selectedDate),
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

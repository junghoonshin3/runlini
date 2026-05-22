// 기록 레이스 선택 시트의 헤더와 빈 상태 섹션을 렌더링한다
part of 'record_race_session_picker_sheet.dart';

class _RecordRaceSessionSheetHeader extends StatelessWidget {
  const _RecordRaceSessionSheetHeader({
    required this.titleStyle,
    required this.descriptionStyle,
  });

  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            key: const Key('record-race-session-drag-handle'),
            width: 56,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('기록 레이스 선택', style: titleStyle),
        const SizedBox(height: 8),
        Text('오늘 달릴 기준 기록을 확인하고 골라요.', style: descriptionStyle),
      ],
    );
  }
}

class _RecordRaceCandidateSectionHeader extends StatelessWidget {
  const _RecordRaceCandidateSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '다른 기록',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.chalk,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count개',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _EmptyRecordRaceSessionState extends StatelessWidget {
  const _EmptyRecordRaceSessionState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('record-race-session-empty-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.muted, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '경로가 있는 러닝 기록을 저장하면 기록 레이스를 시작할 수 있어요.',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
      ),
    );
  }
}

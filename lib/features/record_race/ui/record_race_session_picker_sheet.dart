// 기록 레이스 기록을 확인하고 선택하는 바텀시트 화면
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/record_race/ui/record_race_session_picker_cards.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

class RecordRaceSessionPickerSheet extends ConsumerStatefulWidget {
  const RecordRaceSessionPickerSheet({
    super.key,
    required this.summaries,
    this.recommendedSummary,
    this.recommendationReason,
  });

  final List<RunSessionSummary> summaries;
  final RunSessionSummary? recommendedSummary;
  final String? recommendationReason;

  @override
  ConsumerState<RecordRaceSessionPickerSheet> createState() =>
      _RecordRaceSessionPickerSheetState();
}

class _RecordRaceSessionPickerSheetState
    extends ConsumerState<RecordRaceSessionPickerSheet> {
  String? _expandedSummaryId;

  @override
  void initState() {
    super.initState();
    _expandedSummaryId = _initialExpandedSummaryId(
      _selectableSummaries(widget.summaries),
    );
  }

  @override
  void didUpdateWidget(covariant RecordRaceSessionPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectableSummaries = _selectableSummaries(widget.summaries);
    if (selectableSummaries.isEmpty) {
      _expandedSummaryId = null;
      return;
    }
    final expandedStillExists = selectableSummaries.any(
      (RunSessionSummary summary) => summary.id == _expandedSummaryId,
    );
    final recommendationChanged =
        oldWidget.recommendedSummary?.id != widget.recommendedSummary?.id;
    if (!expandedStillExists || recommendationChanged) {
      _expandedSummaryId = _initialExpandedSummaryId(selectableSummaries);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectableSummaries = _selectableSummaries(widget.summaries);
    final recommendedSummary = _recommendedSummary(selectableSummaries);
    final candidateSummaries = recommendedSummary == null
        ? selectableSummaries
        : selectableSummaries
              .where((summary) => summary.id != recommendedSummary.id)
              .toList(growable: false);

    return DraggableScrollableSheet(
      key: const Key('record-race-session-draggable-sheet'),
      expand: false,
      initialChildSize: 1.0,
      minChildSize: 0.0,
      maxChildSize: 1.0,
      snap: true,
      snapAnimationDuration: const Duration(milliseconds: 80),
      shouldCloseOnMinExtent: true,
      builder: (BuildContext context, ScrollController scrollController) {
        return SafeArea(
          top: true,
          child: Container(
            key: const Key('record-race-session-sheet'),
            color: AppColors.black,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _RecordRaceSessionSheetHeader(
                      titleStyle: Theme.of(context).textTheme.headlineMedium,
                      descriptionStyle: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ),
                ),
                if (selectableSummaries.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyRecordRaceSessionState(),
                    ),
                  )
                else ...[
                  if (recommendedSummary != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: ExpandedRecordRaceSessionCard(
                          key: const Key(
                            'record-race-session-recommendation-card',
                          ),
                          summary: recommendedSummary,
                          sessionAsync: ref.watch(
                            runSessionByIdProvider(recommendedSummary.id),
                          ),
                          badgeLabel: '오늘 추천',
                          reasonLabel: widget.recommendationReason,
                          onSelect: () =>
                              Navigator.of(context).pop(recommendedSummary),
                        ),
                      ),
                    ),
                  if (recommendedSummary != null &&
                      candidateSummaries.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _RecordRaceCandidateSectionHeader(
                          count: candidateSummaries.length,
                        ),
                      ),
                    ),
                  if (candidateSummaries.isNotEmpty)
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        recommendedSummary == null ? 18 : 12,
                        20,
                        20,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((
                          BuildContext context,
                          int index,
                        ) {
                          if (index.isOdd) {
                            return const SizedBox(height: 12);
                          }
                          final summary = candidateSummaries[index ~/ 2];
                          final isExpanded = summary.id == _expandedSummaryId;
                          if (isExpanded) {
                            return ExpandedRecordRaceSessionCard(
                              key: Key(
                                'record-race-session-item-${summary.id}',
                              ),
                              summary: summary,
                              sessionAsync: ref.watch(
                                runSessionByIdProvider(summary.id),
                              ),
                              badgeLabel: '경로 가능',
                              onSelect: () =>
                                  Navigator.of(context).pop(summary),
                            );
                          }
                          return CollapsedRecordRaceSessionCard(
                            key: Key('record-race-session-item-${summary.id}'),
                            summary: summary,
                            badgeLabel: '경로 가능',
                            onTap: () {
                              setState(() => _expandedSummaryId = summary.id);
                            },
                          );
                        }, childCount: candidateSummaries.length * 2 - 1),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String? _initialExpandedSummaryId(List<RunSessionSummary> summaries) {
    final recommended = _recommendedSummary(summaries);
    if (recommended != null) {
      return recommended.id;
    }
    return summaries.isEmpty ? null : summaries.first.id;
  }

  RunSessionSummary? _recommendedSummary(List<RunSessionSummary> summaries) {
    final recommended = widget.recommendedSummary;
    if (recommended == null) {
      return null;
    }
    for (final summary in summaries) {
      if (summary.id == recommended.id) {
        return summary;
      }
    }
    return null;
  }

  List<RunSessionSummary> _selectableSummaries(
    List<RunSessionSummary> summaries,
  ) {
    return summaries
        .where(_isSelectableRecordRaceSummary)
        .toList(growable: false);
  }

  bool _isSelectableRecordRaceSummary(RunSessionSummary summary) {
    return summary.distanceM > 0 &&
        summary.durationMs > 0 &&
        summary.pointCount >= 2 &&
        summary.averagePaceSecPerKm.isFinite &&
        summary.averagePaceSecPerKm > 0;
  }
}

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

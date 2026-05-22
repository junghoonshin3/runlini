// 기록 레이스 기록을 확인하고 선택하는 바텀시트 화면
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_motion.dart';
import 'package:runlini/features/record_race/ui/record_race_session_picker_cards.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

part 'record_race_session_picker_sheet_sections.dart';

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
      snapAnimationDuration: RunliniMotion.enabledDuration(
        context,
        RunliniMotion.fastTransition,
      ),
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
                        child: RunliniFadeUp(
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
                          final card = isExpanded
                              ? ExpandedRecordRaceSessionCard(
                                  key: Key(
                                    'record-race-session-item-${summary.id}',
                                  ),
                                  summary: summary,
                                  sessionAsync: ref.watch(
                                    runSessionByIdProvider(summary.id),
                                  ),
                                  badgeLabel: '코스 있음',
                                  onSelect: () =>
                                      Navigator.of(context).pop(summary),
                                )
                              : CollapsedRecordRaceSessionCard(
                                  key: Key(
                                    'record-race-session-item-${summary.id}',
                                  ),
                                  summary: summary,
                                  badgeLabel: '코스 있음',
                                  onTap: () {
                                    setState(
                                      () => _expandedSummaryId = summary.id,
                                    );
                                  },
                                );
                          if (RunliniMotion.reduceMotion(context)) {
                            return card;
                          }
                          return AnimatedSize(
                            duration: RunliniMotion.shortTransition,
                            curve: RunliniMotion.enterCurve,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: RunliniMotion.shortTransition,
                              switchInCurve: RunliniMotion.enterCurve,
                              switchOutCurve: RunliniMotion.exitCurve,
                              child: KeyedSubtree(
                                key: ValueKey<String>(
                                  '${summary.id}-$isExpanded',
                                ),
                                child: card,
                              ),
                            ),
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

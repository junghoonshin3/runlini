// 고스트 기록을 확인하고 선택하는 바텀시트 화면
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/ghost_racer/ui/ghost_session_picker_cards.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

class GhostSessionPickerSheet extends ConsumerStatefulWidget {
  const GhostSessionPickerSheet({super.key, required this.summaries});

  final List<RunSessionSummary> summaries;

  @override
  ConsumerState<GhostSessionPickerSheet> createState() =>
      _GhostSessionPickerSheetState();
}

class _GhostSessionPickerSheetState
    extends ConsumerState<GhostSessionPickerSheet> {
  String? _expandedSummaryId;

  @override
  void initState() {
    super.initState();
    _expandedSummaryId = widget.summaries.isEmpty
        ? null
        : widget.summaries.first.id;
  }

  @override
  void didUpdateWidget(covariant GhostSessionPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.summaries.isEmpty) {
      _expandedSummaryId = null;
      return;
    }
    final expandedStillExists = widget.summaries.any(
      (RunSessionSummary summary) => summary.id == _expandedSummaryId,
    );
    if (!expandedStillExists) {
      _expandedSummaryId = widget.summaries.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      key: const Key('ghost-session-draggable-sheet'),
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
            key: const Key('ghost-session-sheet'),
            color: AppColors.black,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _GhostSessionSheetHeader(
                      titleStyle: Theme.of(context).textTheme.headlineMedium,
                      descriptionStyle: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ),
                ),
                if (widget.summaries.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyGhostSessionState(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        if (index.isOdd) {
                          return const SizedBox(height: 12);
                        }
                        final summary = widget.summaries[index ~/ 2];
                        final isExpanded = summary.id == _expandedSummaryId;
                        if (isExpanded) {
                          return ExpandedGhostSessionCard(
                            key: Key('ghost-session-item-${summary.id}'),
                            summary: summary,
                            sessionAsync: ref.watch(
                              runSessionByIdProvider(summary.id),
                            ),
                            onSelect: () => Navigator.of(context).pop(summary),
                          );
                        }
                        return CollapsedGhostSessionCard(
                          key: Key('ghost-session-item-${summary.id}'),
                          summary: summary,
                          onTap: () {
                            setState(() => _expandedSummaryId = summary.id);
                          },
                        );
                      }, childCount: widget.summaries.length * 2 - 1),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GhostSessionSheetHeader extends StatelessWidget {
  const _GhostSessionSheetHeader({
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
            key: const Key('ghost-session-drag-handle'),
            width: 56,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('고스트 기록 선택', style: titleStyle),
        const SizedBox(height: 8),
        Text('코스를 확인한 뒤 오늘의 기준선으로 띄웁니다.', style: descriptionStyle),
      ],
    );
  }
}

class _EmptyGhostSessionState extends StatelessWidget {
  const _EmptyGhostSessionState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('ghost-session-empty-state'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.muted, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '고스트로 사용할 기록이 아직 없어요.',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
      ),
    );
  }
}

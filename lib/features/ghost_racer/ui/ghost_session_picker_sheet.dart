import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/ui/history/run_session_summary_tile.dart';

class GhostSessionPickerSheet extends StatelessWidget {
  const GhostSessionPickerSheet({super.key, required this.summaries});

  final List<RunSessionSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      key: const Key('ghost-session-draggable-sheet'),
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.38,
      maxChildSize: 0.96,
      snap: true,
      snapSizes: const <double>[0.68, 0.96],
      builder: (BuildContext context, ScrollController scrollController) {
        return SafeArea(
          top: false,
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
                if (summaries.isEmpty)
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
                        final summary = summaries[index ~/ 2];
                        return RunSessionSummaryTile(
                          key: Key('ghost-session-item-${summary.id}'),
                          summary: summary,
                          onTap: () => Navigator.of(context).pop(summary),
                        );
                      }, childCount: summaries.length * 2 - 1),
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
        Text('이전에 뛰었던 기록을 골라서 지도 위에 기준선으로 띄웁니다.', style: descriptionStyle),
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

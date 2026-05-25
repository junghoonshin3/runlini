// 기록 탭 초기 로딩 상태를 표현하는 스켈레톤 UI
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_skeleton.dart';

class HistoryTabSkeleton extends StatelessWidget {
  const HistoryTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      key: Key('history-tab-skeleton'),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RunliniSkeletonText(width: 92, height: 36),
          SizedBox(height: 10),
          RunliniSkeletonText(width: 260, height: 14),
          SizedBox(height: 18),
          _HistoryDistanceSkeleton(),
          SizedBox(height: 14),
          _HistoryCalendarSkeleton(),
          SizedBox(height: 14),
          RunliniSkeletonText(width: 108, height: 20),
          SizedBox(height: 14),
          RunliniSkeletonTile(),
          SizedBox(height: 14),
          RunliniSkeletonTile(),
        ],
      ),
    );
  }
}

class _HistoryDistanceSkeleton extends StatelessWidget {
  const _HistoryDistanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return RunliniSkeletonPanel(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.voltGreen.withValues(alpha: 0.26),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(child: RunliniSkeletonBox(height: 40)),
              SizedBox(width: 8),
              Expanded(child: RunliniSkeletonBox(height: 40)),
              SizedBox(width: 8),
              Expanded(child: RunliniSkeletonBox(height: 40)),
            ],
          ),
          SizedBox(height: 22),
          Center(
            child: SizedBox.square(
              dimension: 138,
              child: RunliniSkeletonBox(height: 138, borderRadius: 69),
            ),
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: RunliniSkeletonBox(height: 58)),
              SizedBox(width: 10),
              Expanded(child: RunliniSkeletonBox(height: 58)),
              SizedBox(width: 10),
              Expanded(child: RunliniSkeletonBox(height: 58)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCalendarSkeleton extends StatelessWidget {
  const _HistoryCalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return RunliniSkeletonPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RunliniSkeletonText(width: 138, height: 22),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List<Widget>.generate(
              35,
              (_) => const RunliniSkeletonBox(height: 34, borderRadius: 6),
            ),
          ),
        ],
      ),
    );
  }
}

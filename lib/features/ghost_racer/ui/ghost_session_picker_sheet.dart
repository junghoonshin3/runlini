import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/ui/run_session_summary_tile.dart';

class GhostSessionPickerSheet extends StatelessWidget {
  const GhostSessionPickerSheet({super.key, required this.summaries});

  final List<RunSessionSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('ghost-session-sheet'),
        color: AppColors.black,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '고스트 기록 선택',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '이전에 뛰었던 기록을 골라서 지도 위에 기준선으로 띄웁니다.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 420,
              child: ListView.separated(
                itemCount: summaries.length,
                itemBuilder: (BuildContext context, int index) {
                  final summary = summaries[index];
                  return RunSessionSummaryTile(
                    key: Key('ghost-session-item-${summary.id}'),
                    summary: summary,
                    onTap: () => Navigator.of(context).pop(summary),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

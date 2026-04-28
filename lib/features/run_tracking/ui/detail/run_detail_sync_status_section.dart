import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/common/run_compact_button.dart';
import 'package:runlini/features/run_tracking/ui/common/run_sync_status_badge.dart';

class RunDetailSyncStatusSection extends StatelessWidget {
  const RunDetailSyncStatusSection({
    super.key,
    required this.status,
    this.onRetry,
  });

  final RunSessionSyncStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('detail-sync-status-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          RunSyncStatusBadge(status: status),
          if (status == RunSessionSyncStatus.syncFailed)
            RunCompactButton(
              key: const Key('retry-health-backup-button'),
              label: 'Health 백업 다시 시도',
              onPressed: onRetry,
              danger: true,
            ),
        ],
      ),
    );
  }
}

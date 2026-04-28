import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunSyncStatusBadge extends StatelessWidget {
  const RunSyncStatusBadge({super.key, required this.status});

  final RunSessionSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      key: const Key('run-sync-status-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        runSyncStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

String runSyncStatusLabel(RunSessionSyncStatus status) {
  return switch (status) {
    RunSessionSyncStatus.synced => 'Health 백업됨',
    RunSessionSyncStatus.syncFailed => '백업 실패',
    RunSessionSyncStatus.localOnly ||
    RunSessionSyncStatus.syncSkipped => '앱에만 저장됨',
  };
}

Color _color(RunSessionSyncStatus status) {
  return switch (status) {
    RunSessionSyncStatus.synced => AppColors.voltGreen,
    RunSessionSyncStatus.syncFailed => AppColors.electricRed,
    RunSessionSyncStatus.localOnly ||
    RunSessionSyncStatus.syncSkipped => AppColors.amber,
  };
}

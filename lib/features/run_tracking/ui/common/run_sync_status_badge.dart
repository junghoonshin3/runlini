import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/health/health_destination_labels.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunSyncStatusBadge extends StatelessWidget {
  const RunSyncStatusBadge({
    super.key,
    required this.status,
    this.recordSource = RunSessionRecordSource.appLocal,
    this.sourceSummary = '',
    this.targetPlatform,
  });

  final RunSessionSyncStatus status;
  final RunSessionRecordSource recordSource;
  final String sourceSummary;
  final TargetPlatform? targetPlatform;

  @override
  Widget build(BuildContext context) {
    final color = _color(status, recordSource);
    return Container(
      key: const Key('run-sync-status-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        runSyncStatusLabel(
          status,
          recordSource: recordSource,
          sourceSummary: sourceSummary,
          targetPlatform: targetPlatform,
        ),
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

String runSyncStatusLabel(
  RunSessionSyncStatus status, {
  RunSessionRecordSource recordSource = RunSessionRecordSource.appLocal,
  String sourceSummary = '',
  TargetPlatform? targetPlatform,
}) {
  if (recordSource == RunSessionRecordSource.healthConnect) {
    return _healthSourceLabel(
      sourceSummary: sourceSummary,
      fallback: 'Health Connect에서 가져옴',
    );
  }
  if (recordSource == RunSessionRecordSource.healthKit) {
    return _healthSourceLabel(
      sourceSummary: sourceSummary,
      fallback: '건강 앱에서 가져옴',
    );
  }
  final platform = targetPlatform ?? defaultTargetPlatform;
  return switch (status) {
    RunSessionSyncStatus.synced => healthDestinationSavedLabel(platform),
    RunSessionSyncStatus.syncFailed => healthDestinationFailedLabel(platform),
    RunSessionSyncStatus.localOnly ||
    RunSessionSyncStatus.syncSkipped => '앱에만 저장됨',
  };
}

String _healthSourceLabel({
  required String sourceSummary,
  required String fallback,
}) {
  final source = _humanSourceName(sourceSummary);
  if (source == null) {
    return fallback;
  }
  return '$source에서 가져옴';
}

String? _humanSourceName(String sourceSummary) {
  final summary = sourceSummary.trim();
  if (summary.isEmpty ||
      summary == 'Health Connect' ||
      summary == 'Apple Health') {
    return null;
  }
  final parts = summary.split('·');
  final candidate = (parts.length > 1 ? parts.last : summary).trim();
  if (candidate.isEmpty || _looksLikePackageName(candidate)) {
    return null;
  }
  return candidate;
}

bool _looksLikePackageName(String value) {
  return RegExp(r'^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$').hasMatch(value);
}

Color _color(RunSessionSyncStatus status, RunSessionRecordSource recordSource) {
  if (recordSource != RunSessionRecordSource.appLocal) {
    return AppColors.voltGreen;
  }
  return switch (status) {
    RunSessionSyncStatus.synced => AppColors.voltGreen,
    RunSessionSyncStatus.syncFailed => AppColors.electricRed,
    RunSessionSyncStatus.localOnly ||
    RunSessionSyncStatus.syncSkipped => AppColors.amber,
  };
}

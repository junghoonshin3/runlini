import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/health_sync/state/health_backup_providers.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/service/wear_draft_sync_service.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/settings/ui/settings_display_section.dart';
import 'package:runlini/features/settings/ui/settings_distance_goal_section.dart';
import 'package:runlini/features/settings/ui/settings_privacy_section.dart';
import 'package:runlini/features/settings/ui/settings_profile_section.dart';
import 'package:runlini/features/settings/ui/settings_running_section.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';
import 'package:runlini/features/settings/ui/settings_shoe_section.dart';

class SettingsTabScreen extends ConsumerWidget {
  const SettingsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(runSettingsControllerProvider).value ??
        const RunSettingsState();

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const Key('settings-tab-screen'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            '설정',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontSize: 34),
          ),
          const SizedBox(height: 16),
          SettingsRunningSection(settings: settings),
          const SizedBox(height: 14),
          SettingsProfileSection(settings: settings),
          const SizedBox(height: 14),
          SettingsDisplaySection(settings: settings.display),
          const SizedBox(height: 14),
          SettingsDistanceGoalSection(settings: settings),
          const SizedBox(height: 14),
          SettingsPrivacySection(settings: settings.privacy),
          const SizedBox(height: 14),
          const SettingsShoeSection(),
          const SizedBox(height: 14),
          const _SettingsSyncSection(),
        ],
      ),
    );
  }
}

class _SettingsSyncSection extends ConsumerWidget {
  const _SettingsSyncSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(healthSyncControllerProvider);
    final backupState = ref.watch(healthBackupControllerProvider);
    final wearSyncState = ref.watch(wearDraftSyncControllerProvider);
    final sessions =
        ref.watch(runSessionListProvider).value ?? const <RunSession>[];
    final failedCount = sessions.where((RunSession session) {
      return session.syncStatus == RunSessionSyncStatus.syncFailed;
    }).length;
    final unsyncedAppCount = sessions.where((RunSession session) {
      return session.recordSource == RunSessionRecordSource.appLocal &&
          session.syncStatus != RunSessionSyncStatus.synced;
    }).length;
    final status = syncState.value ?? const HealthSyncStatus.idle();
    final isBusy = syncState.isLoading || backupState.isLoading;
    final isWearBusy = wearSyncState.isLoading;
    return SettingsSectionPanel(
      title: '연동',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsStatusRow(
            label: 'Health Connect',
            value: _statusText(status),
          ),
          SettingsStatusRow(
            label: 'Wear OS',
            value: _wearStatusText(wearSyncState.value, isWearBusy),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SettingsCompactButton(
                key: const Key('settings-wear-sync-button'),
                label: isWearBusy ? '처리 중...' : '워치 기록 동기화',
                onPressed: isWearBusy
                    ? null
                    : () => _syncWearRecords(context, ref),
              ),
              SettingsCompactButton(
                key: const Key('settings-health-import-button'),
                label: isBusy ? '처리 중...' : 'Health 기록 가져오기',
                onPressed: isBusy
                    ? null
                    : () => _importHealthRecords(context, ref),
              ),
              SettingsCompactButton(
                key: const Key('settings-health-backup-button'),
                label: '앱 기록 Health 백업 ($unsyncedAppCount)',
                onPressed: isBusy || unsyncedAppCount == 0
                    ? null
                    : () => _backupUnsyncedRuns(context, ref),
              ),
              SettingsCompactButton(
                key: const Key('settings-health-retry-failed-button'),
                label: '백업 실패 재시도 ($failedCount)',
                danger: failedCount > 0,
                onPressed: isBusy || failedCount == 0
                    ? null
                    : () => _retryFailedBackups(context, ref),
              ),
            ],
          ),
          if (syncState.hasError)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('동기화 실패', style: _errorStyle),
            ),
          if (wearSyncState.hasError)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('워치 동기화 실패', style: _errorStyle),
            ),
        ],
      ),
    );
  }

  String _statusText(HealthSyncStatus status) {
    return switch (status.kind) {
      HealthSyncStatusKind.idle => '대기',
      HealthSyncStatusKind.syncing => '동기화 중',
      HealthSyncStatusKind.synced => '동기화됨',
      HealthSyncStatusKind.connectionNeeded => '연결 필요',
      HealthSyncStatusKind.unavailable => '지원 필요',
      HealthSyncStatusKind.failed => '실패',
    };
  }

  String _wearStatusText(WearDraftSyncResult? result, bool isLoading) {
    if (isLoading) {
      return '동기화 중';
    }
    if (result == null) {
      return '대기';
    }
    if (result.failedCount > 0) {
      return '실패';
    }
    if (result.importedCount > 0 || result.ackedCount > 0) {
      return '동기화됨';
    }
    return '대기';
  }

  Future<void> _syncWearRecords(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(wearDraftSyncControllerProvider.notifier)
        .syncPendingDrafts();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_wearSyncMessage(result))));
  }

  String _wearSyncMessage(WearDraftSyncResult result) {
    if (result.failedCount > 0) {
      return '일부 워치 기록을 가져오지 못했어요.';
    }
    if (result.importedCount > 0) {
      return '${result.importedCount}개의 워치 기록을 가져왔어요.';
    }
    return '가져올 워치 기록이 없어요.';
  }

  Future<void> _importHealthRecords(BuildContext context, WidgetRef ref) async {
    final status = await ref
        .read(healthSyncControllerProvider.notifier)
        .syncWithUserAction();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_importMessage(status))));
  }

  String _importMessage(HealthSyncStatus status) {
    return switch (status.kind) {
      HealthSyncStatusKind.synced => 'Health 기록 가져오기를 마쳤어요.',
      HealthSyncStatusKind.connectionNeeded => 'Health 권한이 필요해요.',
      HealthSyncStatusKind.unavailable => 'Health Connect 설치 또는 지원이 필요해요.',
      HealthSyncStatusKind.failed => 'Health 기록을 가져오지 못했어요.',
      HealthSyncStatusKind.idle ||
      HealthSyncStatusKind.syncing => 'Health 기록 가져오기를 마쳤어요.',
    };
  }

  Future<void> _retryFailedBackups(BuildContext context, WidgetRef ref) async {
    final count = await ref
        .read(healthBackupControllerProvider.notifier)
        .retryFailedSessions();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$count개의 기록을 Health에 다시 백업했어요.')));
  }

  Future<void> _backupUnsyncedRuns(BuildContext context, WidgetRef ref) async {
    final count = await ref
        .read(healthBackupControllerProvider.notifier)
        .backupUnsyncedAppSessions();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$count개의 앱 기록을 Health에 백업했어요.')));
  }
}

const _errorStyle = TextStyle(
  color: AppColors.electricRed,
  fontWeight: FontWeight.w900,
);

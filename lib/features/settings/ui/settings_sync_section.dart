import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/features/health_sync/state/health_backup_providers.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/service/wear_draft_sync_service.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';
import 'package:runlini/features/settings/ui/settings_sync_card.dart';

final settingsTargetPlatformProvider = Provider<TargetPlatform>((Ref ref) {
  return defaultTargetPlatform;
});

class SettingsSyncSection extends ConsumerWidget {
  const SettingsSyncSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = ref.watch(settingsTargetPlatformProvider);
    final syncState = ref.watch(healthSyncControllerProvider);
    final connectionState = ref.watch(healthConnectionStatusProvider);
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
    final isAndroid = platform == TargetPlatform.android;
    final isHealthBusy =
        syncState.isLoading ||
        syncState.value?.kind == HealthSyncStatusKind.syncing;
    final isBackupBusy = backupState.isLoading;
    final healthConnected = _isHealthConnected(syncState, connectionState);
    final healthLabel = _healthPlatformLabel(platform);

    return SettingsSectionPanel(
      title: '연동',
      child: Column(
        children: [
          SettingsSyncCard(
            title: healthLabel,
            status: _healthStatusText(syncState, connectionState, isHealthBusy),
            actionKey: const Key('settings-health-import-button'),
            actionLabel: isHealthBusy
                ? '처리 중...'
                : healthConnected
                ? '최근 기록 가져오기'
                : '$healthLabel 연결',
            onPressed: isHealthBusy
                ? null
                : () => _runHealthAction(
                    context,
                    ref,
                    connected: healthConnected,
                    platform: platform,
                  ),
          ),
          if (isAndroid) ...[
            const SizedBox(height: 10),
            SettingsSyncCard(
              title: 'Wear OS',
              status: _wearStatusText(
                wearSyncState.value,
                wearSyncState.isLoading,
              ),
              actionKey: const Key('settings-wear-sync-button'),
              actionLabel: wearSyncState.isLoading ? '처리 중...' : '워치 기록 동기화',
              onPressed: wearSyncState.isLoading
                  ? null
                  : () => _syncWearRecords(context, ref),
            ),
          ],
          const SizedBox(height: 10),
          SettingsSyncCard(
            title: '백업',
            status: failedCount > 0
                ? '실패 $failedCount개'
                : '대기 $unsyncedAppCount개',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SettingsCompactButton(
                  key: const Key('settings-health-backup-button'),
                  label: '앱 기록 백업 ($unsyncedAppCount)',
                  onPressed:
                      isHealthBusy || isBackupBusy || unsyncedAppCount == 0
                      ? null
                      : () => _backupUnsyncedRuns(context, ref),
                ),
                SettingsCompactButton(
                  key: const Key('settings-health-retry-failed-button'),
                  label: '백업 실패 재시도 ($failedCount)',
                  danger: failedCount > 0,
                  onPressed: isHealthBusy || isBackupBusy || failedCount == 0
                      ? null
                      : () => _retryFailedBackups(context, ref),
                ),
              ],
            ),
          ),
          if (syncState.hasError)
            const SettingsSyncErrorText(label: 'Health 동기화 실패'),
          if (wearSyncState.hasError)
            const SettingsSyncErrorText(label: '워치 동기화 실패'),
        ],
      ),
    );
  }

  bool _isHealthConnected(
    AsyncValue<HealthSyncStatus> syncState,
    AsyncValue<HealthRouteConnectionStatus> connectionState,
  ) {
    if (syncState.value?.kind == HealthSyncStatusKind.synced) {
      return true;
    }
    return connectionState.value?.kind ==
        HealthRouteConnectionStatusKind.connected;
  }

  String _healthPlatformLabel(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return '건강 앱';
    }
    if (platform == TargetPlatform.android) {
      return 'Health Connect';
    }
    return 'Health';
  }

  String _healthStatusText(
    AsyncValue<HealthSyncStatus> syncState,
    AsyncValue<HealthRouteConnectionStatus> connectionState,
    bool isBusy,
  ) {
    if (isBusy) {
      return '처리 중';
    }
    final syncStatus = syncState.value;
    if (syncStatus != null && syncStatus.kind != HealthSyncStatusKind.idle) {
      return switch (syncStatus.kind) {
        HealthSyncStatusKind.synced => '연결됨',
        HealthSyncStatusKind.connectionNeeded => '권한 필요',
        HealthSyncStatusKind.unavailable => '지원 필요',
        HealthSyncStatusKind.failed => '실패',
        HealthSyncStatusKind.idle || HealthSyncStatusKind.syncing => '대기',
      };
    }
    if (connectionState.isLoading) {
      return '확인 중';
    }
    return switch (connectionState.value?.kind) {
      HealthRouteConnectionStatusKind.connected => '연결됨',
      HealthRouteConnectionStatusKind.connectionNeeded => '권한 필요',
      HealthRouteConnectionStatusKind.unavailable => '지원 필요',
      HealthRouteConnectionStatusKind.failed => '실패',
      null => '대기',
    };
  }

  Future<void> _runHealthAction(
    BuildContext context,
    WidgetRef ref, {
    required bool connected,
    required TargetPlatform platform,
  }) async {
    final controller = ref.read(healthSyncControllerProvider.notifier);
    final status = connected
        ? await controller.syncIfAuthorized()
        : await controller.connectAndSync();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _healthMessage(status, platform: platform, connected: connected),
        ),
      ),
    );
  }

  String _healthMessage(
    HealthSyncStatus status, {
    required TargetPlatform platform,
    required bool connected,
  }) {
    final label = _healthPlatformLabel(platform);
    return switch (status.kind) {
      HealthSyncStatusKind.synced =>
        connected ? '최근 기록 가져오기를 마쳤어요.' : '$label 연결됨',
      HealthSyncStatusKind.connectionNeeded => '$label 권한이 필요해요.',
      HealthSyncStatusKind.unavailable =>
        platform == TargetPlatform.iOS
            ? '건강 앱을 사용할 수 없어요.'
            : 'Health Connect 설치 또는 지원이 필요해요.',
      HealthSyncStatusKind.failed => 'Health 기록을 가져오지 못했어요.',
      HealthSyncStatusKind.idle ||
      HealthSyncStatusKind.syncing => '최근 기록 가져오기를 마쳤어요.',
    };
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

  String _wearSyncMessage(WearDraftSyncResult result) {
    if (result.failedCount > 0) {
      return '일부 워치 기록을 가져오지 못했어요.';
    }
    if (result.importedCount > 0) {
      return '${result.importedCount}개의 워치 기록을 가져왔어요.';
    }
    return '가져올 워치 기록이 없어요.';
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

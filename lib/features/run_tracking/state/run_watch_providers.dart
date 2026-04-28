import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/wear/watch_ghost_config_client.dart';
import 'package:runlini/core/wear/wear_draft_inbox_client.dart';
import 'package:runlini/features/run_tracking/service/watch_ghost_config_sync_service.dart';
import 'package:runlini/features/run_tracking/service/watch_run_session_import_service.dart';
import 'package:runlini/features/run_tracking/service/wear_draft_sync_service.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';

final watchRunSessionImportServiceProvider =
    Provider<WatchRunSessionImportService>((Ref ref) {
      return WatchRunSessionImportService(
        repository: ref.watch(runSessionRepositoryProvider),
      );
    });

final wearDraftInboxClientProvider = Provider<WearDraftInboxClient>((Ref ref) {
  return const MethodChannelWearDraftInboxClient();
});

final watchGhostConfigClientProvider = Provider<WatchGhostConfigClient>((
  Ref ref,
) {
  return const MethodChannelWatchGhostConfigClient();
});

final watchGhostConfigSyncServiceProvider =
    Provider<WatchGhostConfigSyncService>((Ref ref) {
      return WatchGhostConfigSyncService(
        client: ref.watch(watchGhostConfigClientProvider),
      );
    });

final wearDraftSyncServiceProvider = Provider<WearDraftSyncService>((Ref ref) {
  return WearDraftSyncService(
    inboxClient: ref.watch(wearDraftInboxClientProvider),
    importService: ref.watch(watchRunSessionImportServiceProvider),
  );
});

class WearDraftSyncController extends AsyncNotifier<WearDraftSyncResult?> {
  @override
  FutureOr<WearDraftSyncResult?> build() {
    return null;
  }

  Future<WearDraftSyncResult> syncPendingDrafts() async {
    state = const AsyncValue<WearDraftSyncResult?>.loading();
    final result = await AsyncValue.guard(
      () => ref.read(wearDraftSyncServiceProvider).syncPendingDrafts(),
    );
    state = result;
    if (result.hasValue) {
      final syncResult = result.requireValue;
      if (syncResult.hasChanges) {
        ref.invalidate(runSessionListProvider);
        ref.invalidate(runSessionSummaryListProvider);
      }
      return syncResult;
    }

    final failed = const WearDraftSyncResult.failed();
    state = AsyncValue<WearDraftSyncResult?>.data(failed);
    return failed;
  }
}

final wearDraftSyncControllerProvider =
    AsyncNotifierProvider<WearDraftSyncController, WearDraftSyncResult?>(
      WearDraftSyncController.new,
    );

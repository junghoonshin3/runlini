import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/wear/watch_connection_client.dart';
import 'package:runlini/core/wear/watch_interval_config_client.dart';
import 'package:runlini/core/wear/watch_record_race_config_client.dart';
import 'package:runlini/core/wear/watch_voice_settings_client.dart';
import 'package:runlini/core/wear/wear_draft_inbox_client.dart';
import 'package:runlini/features/run_tracking/service/watch_record_race_config_sync_service.dart';
import 'package:runlini/features/run_tracking/service/watch_run_session_import_service.dart';
import 'package:runlini/features/run_tracking/service/wear_draft_sync_service.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

final watchRunSessionImportServiceProvider =
    Provider<WatchRunSessionImportService>((Ref ref) {
      return WatchRunSessionImportService(
        repository: ref.watch(runSessionRepositoryProvider),
      );
    });

final wearDraftInboxClientProvider = Provider<WearDraftInboxClient>((Ref ref) {
  return const MethodChannelWearDraftInboxClient();
});

final watchRecordRaceConfigClientProvider =
    Provider<WatchRecordRaceConfigClient>((Ref ref) {
      return const MethodChannelWatchRecordRaceConfigClient();
    });

final watchIntervalConfigClientProvider = Provider<WatchIntervalConfigClient>((
  Ref ref,
) {
  return const MethodChannelWatchIntervalConfigClient();
});

final watchVoiceSettingsClientProvider = Provider<WatchVoiceSettingsClient>((
  Ref ref,
) {
  return const MethodChannelWatchVoiceSettingsClient();
});

final watchConnectionClientProvider = Provider<WatchConnectionClient>((
  Ref ref,
) {
  return const MethodChannelWatchConnectionClient();
});

final watchRecordRaceConfigSyncServiceProvider =
    Provider<WatchRecordRaceConfigSyncService>((Ref ref) {
      return WatchRecordRaceConfigSyncService(
        client: ref.watch(watchRecordRaceConfigClientProvider),
      );
    });

final recentWatchRecordRaceSessionsProvider =
    FutureProvider.family<List<RunSession>, String?>((
      Ref ref,
      selectedId,
    ) async {
      final summaries = await ref.watch(runSessionSummaryListProvider.future);
      final runnableSummaries =
          summaries.where((summary) => summary.pointCount >= 2).toList()
            ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
      final selectedSummary = selectedId == null
          ? null
          : _firstSummaryWithId(runnableSummaries, selectedId);
      final ids = <String>[
        if (selectedSummary != null) selectedSummary.id,
        for (final summary in runnableSummaries)
          if (summary.id != selectedSummary?.id) summary.id,
      ].take(3).toList(growable: false);
      final sessions = <RunSession>[];
      for (final id in ids) {
        final session = await ref.watch(runSessionByIdProvider(id).future);
        if (session != null && session.points.length >= 2) {
          sessions.add(session);
        }
      }
      return List<RunSession>.unmodifiable(sessions);
    });

RunSessionSummary? _firstSummaryWithId(
  Iterable<RunSessionSummary> summaries,
  String id,
) {
  for (final summary in summaries) {
    if (summary.id == id) {
      return summary;
    }
  }
  return null;
}

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

class WatchConnectionStatusController
    extends AsyncNotifier<WatchConnectionStatus?> {
  @override
  FutureOr<WatchConnectionStatus?> build() {
    return null;
  }

  Future<WatchConnectionStatus> check() async {
    state = const AsyncValue<WatchConnectionStatus?>.loading();
    final result = await AsyncValue.guard(
      () => ref.read(watchConnectionClientProvider).connectionStatus(),
    );
    if (result.hasValue) {
      final status = result.requireValue;
      state = AsyncValue<WatchConnectionStatus?>.data(status);
      return status;
    }

    const fallback = WatchConnectionStatus.disconnected;
    state = const AsyncValue<WatchConnectionStatus?>.data(fallback);
    return fallback;
  }
}

final watchConnectionStatusProvider =
    AsyncNotifierProvider<
      WatchConnectionStatusController,
      WatchConnectionStatus?
    >(WatchConnectionStatusController.new);

import 'package:runlini/core/wear/wear_draft_inbox_client.dart';
import 'package:runlini/features/run_tracking/service/watch_run_session_import_service.dart';

class WearDraftSyncResult {
  const WearDraftSyncResult({
    required this.pendingCount,
    required this.importedCount,
    required this.ackedCount,
    required this.failedCount,
  });

  const WearDraftSyncResult.failed()
    : pendingCount = 0,
      importedCount = 0,
      ackedCount = 0,
      failedCount = 1;

  final int pendingCount;
  final int importedCount;
  final int ackedCount;
  final int failedCount;

  bool get hasChanges => importedCount > 0 || ackedCount > 0;
}

class WearDraftSyncService {
  const WearDraftSyncService({
    required WearDraftInboxClient inboxClient,
    required WatchRunSessionImportService importService,
  }) : _inboxClient = inboxClient,
       _importService = importService;

  final WearDraftInboxClient _inboxClient;
  final WatchRunSessionImportService _importService;

  Future<WearDraftSyncResult> syncPendingDrafts() async {
    final drafts = await _readPendingDrafts();
    if (drafts == null) {
      return const WearDraftSyncResult.failed();
    }

    var importedCount = 0;
    var ackedCount = 0;
    var failedCount = 0;
    for (final envelope in drafts) {
      try {
        final session = await _importService.importDraft(envelope.draft);
        if (session != null) {
          importedCount += 1;
        }
        await _inboxClient.ackWearDraft(envelope.id);
        ackedCount += 1;
      } catch (_) {
        failedCount += 1;
      }
    }

    return WearDraftSyncResult(
      pendingCount: drafts.length,
      importedCount: importedCount,
      ackedCount: ackedCount,
      failedCount: failedCount,
    );
  }

  Future<List<WearDraftEnvelope>?> _readPendingDrafts() async {
    try {
      return await _inboxClient.pendingWearDrafts();
    } catch (_) {
      return null;
    }
  }
}

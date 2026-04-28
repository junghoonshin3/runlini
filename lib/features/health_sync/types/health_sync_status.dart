enum HealthSyncStatusKind {
  idle,
  syncing,
  synced,
  connectionNeeded,
  unavailable,
  failed,
}

class HealthSyncStatus {
  const HealthSyncStatus({
    required this.kind,
    this.syncedCount = 0,
    this.message,
  });

  const HealthSyncStatus.idle() : this(kind: HealthSyncStatusKind.idle);

  const HealthSyncStatus.syncing() : this(kind: HealthSyncStatusKind.syncing);

  const HealthSyncStatus.synced(int count)
    : this(kind: HealthSyncStatusKind.synced, syncedCount: count);

  const HealthSyncStatus.connectionNeeded([String? message])
    : this(kind: HealthSyncStatusKind.connectionNeeded, message: message);

  const HealthSyncStatus.unavailable([String? message])
    : this(kind: HealthSyncStatusKind.unavailable, message: message);

  const HealthSyncStatus.failed([String? message])
    : this(kind: HealthSyncStatusKind.failed, message: message);

  final HealthSyncStatusKind kind;
  final int syncedCount;
  final String? message;
}

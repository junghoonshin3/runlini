enum HealthWorkoutExportResultKind { synced, skipped, failed }

class HealthWorkoutExportResult {
  const HealthWorkoutExportResult._({
    required this.kind,
    this.externalId,
    this.message,
  });

  const HealthWorkoutExportResult.synced({String? externalId, String? message})
    : this._(
        kind: HealthWorkoutExportResultKind.synced,
        externalId: externalId,
        message: message,
      );

  const HealthWorkoutExportResult.skipped([String? message])
    : this._(kind: HealthWorkoutExportResultKind.skipped, message: message);

  const HealthWorkoutExportResult.failed([String? message])
    : this._(kind: HealthWorkoutExportResultKind.failed, message: message);

  final HealthWorkoutExportResultKind kind;
  final String? externalId;
  final String? message;
}

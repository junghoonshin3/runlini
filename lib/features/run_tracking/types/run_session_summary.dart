import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunSessionSummary {
  const RunSessionSummary({
    required this.id,
    required this.startedAt,
    required this.distanceM,
    required this.durationMs,
    required this.averagePaceSecPerKm,
    required this.sourceSummary,
    required this.recordSource,
    required this.captureSource,
    required this.syncStatus,
    this.averageCadenceSpm,
    this.shoeId,
    this.pointCount = 0,
  });

  final String id;
  final DateTime startedAt;
  final double distanceM;
  final int durationMs;
  final double averagePaceSecPerKm;
  final String sourceSummary;
  final RunSessionRecordSource recordSource;
  final RunSessionCaptureSource captureSource;
  final RunSessionSyncStatus syncStatus;
  final double? averageCadenceSpm;
  final String? shoeId;
  final int pointCount;

  double get distanceKm => distanceM / 1000;

  factory RunSessionSummary.fromSession(RunSession session) {
    final distanceKm = session.distanceM / 1000;
    final averagePace = distanceKm <= 0
        ? 0.0
        : (session.durationMs / 1000) / distanceKm;

    return RunSessionSummary(
      id: session.id,
      startedAt: session.startedAt,
      distanceM: session.distanceM,
      durationMs: session.durationMs,
      averagePaceSecPerKm: averagePace,
      sourceSummary: session.sourceSummary,
      recordSource: session.recordSource,
      captureSource: session.captureSource,
      syncStatus: session.syncStatus,
      averageCadenceSpm: session.averageCadenceSpm,
      shoeId: session.shoeId,
      pointCount: session.points.length,
    );
  }
}

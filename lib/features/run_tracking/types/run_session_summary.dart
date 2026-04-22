import 'package:runlini/features/run_tracking/types/run_session.dart';

class RunSessionSummary {
  const RunSessionSummary({
    required this.id,
    required this.startedAt,
    required this.distanceM,
    required this.durationMs,
    required this.averagePaceSecPerKm,
    required this.sourceSummary,
    this.averageCadenceSpm,
  });

  final String id;
  final DateTime startedAt;
  final double distanceM;
  final int durationMs;
  final double averagePaceSecPerKm;
  final String sourceSummary;
  final double? averageCadenceSpm;

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
      averageCadenceSpm: session.averageCadenceSpm,
    );
  }
}

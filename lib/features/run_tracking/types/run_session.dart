import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

class RunSession {
  const RunSession({
    required this.id,
    required this.startedAt,
    required this.distanceM,
    required this.durationMs,
    required this.sourceSummary,
    required this.points,
    this.averageCadenceSpm,
    this.endedAt,
    this.ghostSummary,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceM;
  final int durationMs;
  final String sourceSummary;
  final List<RunPoint> points;
  final double? averageCadenceSpm;
  final RunSessionGhostSummary? ghostSummary;

  factory RunSession.fromJson(Map<String, dynamic> json) {
    return RunSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      distanceM: (json['distanceM'] as num).toDouble(),
      durationMs: json['durationMs'] as int,
      sourceSummary: json['sourceSummary'] as String,
      points: (json['points'] as List<dynamic>)
          .map(
            (dynamic point) => RunPoint.fromJson(point as Map<String, dynamic>),
          )
          .toList(growable: false),
      averageCadenceSpm: (json['averageCadenceSpm'] as num?)?.toDouble(),
      ghostSummary: json['ghostSummary'] == null
          ? null
          : RunSessionGhostSummary.fromJson(
              json['ghostSummary'] as Map<String, dynamic>,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'distanceM': distanceM,
      'durationMs': durationMs,
      'sourceSummary': sourceSummary,
      'averageCadenceSpm': averageCadenceSpm,
      'ghostSummary': ghostSummary?.toJson(),
      'points': points
          .map((RunPoint point) => point.toJson())
          .toList(growable: false),
    };
  }
}

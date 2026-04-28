import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class WatchGhostConfig {
  const WatchGhostConfig({
    required this.id,
    required this.startedAt,
    required this.durationMs,
    required this.distanceM,
    required this.sourceSummary,
    required this.points,
  });

  final String id;
  final DateTime startedAt;
  final int durationMs;
  final double distanceM;
  final String sourceSummary;
  final List<RunPoint> points;

  bool get canRunOnWatch => points.length >= 2;

  factory WatchGhostConfig.fromSession(RunSession session) {
    return WatchGhostConfig(
      id: session.id,
      startedAt: session.startedAt,
      durationMs: session.durationMs,
      distanceM: session.distanceM,
      sourceSummary: session.sourceSummary,
      points: session.points,
    );
  }

  factory WatchGhostConfig.fromJson(Map<String, dynamic> json) {
    return WatchGhostConfig(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationMs: json['durationMs'] as int,
      distanceM: (json['distanceM'] as num).toDouble(),
      sourceSummary: json['sourceSummary'] as String,
      points: (json['points'] as List<dynamic>)
          .map(
            (dynamic point) => RunPoint.fromJson(point as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'durationMs': durationMs,
      'distanceM': distanceM,
      'sourceSummary': sourceSummary,
      'points': points.map((RunPoint point) => point.toJson()).toList(),
    };
  }
}

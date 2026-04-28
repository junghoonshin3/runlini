import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/types/watch_run_platform.dart';

class WatchRunDraft {
  const WatchRunDraft({
    required this.id,
    required this.platform,
    required this.startedAt,
    required this.durationMs,
    required this.distanceM,
    required this.points,
    this.endedAt,
    this.externalWorkoutId,
    this.sourceDeviceName,
    this.averageCadenceSpm,
    this.caloriesKcal,
    this.ghostSummary,
  });

  final String id;
  final WatchRunPlatform platform;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMs;
  final double distanceM;
  final List<RunPoint> points;
  final String? externalWorkoutId;
  final String? sourceDeviceName;
  final double? averageCadenceSpm;
  final double? caloriesKcal;
  final RunSessionGhostSummary? ghostSummary;

  factory WatchRunDraft.fromJson(Map<String, dynamic> json) {
    return WatchRunDraft(
      id: json['id'] as String,
      platform: WatchRunPlatform.values.byName(json['platform'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      durationMs: json['durationMs'] as int,
      distanceM: (json['distanceM'] as num).toDouble(),
      points: (json['points'] as List<dynamic>)
          .map(
            (dynamic point) => RunPoint.fromJson(point as Map<String, dynamic>),
          )
          .toList(growable: false),
      externalWorkoutId: json['externalWorkoutId'] as String?,
      sourceDeviceName: json['sourceDeviceName'] as String?,
      averageCadenceSpm: (json['averageCadenceSpm'] as num?)?.toDouble(),
      caloriesKcal: (json['caloriesKcal'] as num?)?.toDouble(),
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
      'platform': platform.name,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationMs': durationMs,
      'distanceM': distanceM,
      'externalWorkoutId': externalWorkoutId,
      'sourceDeviceName': sourceDeviceName,
      'averageCadenceSpm': averageCadenceSpm,
      'caloriesKcal': caloriesKcal,
      'ghostSummary': ghostSummary?.toJson(),
      'points': points.map((RunPoint point) => point.toJson()).toList(),
    };
  }
}

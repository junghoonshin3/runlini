import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';

enum RunSessionRecordSource { appLocal, healthConnect, healthKit }

enum RunSessionCaptureSource { phoneGps, wearOs, watchOs }

enum RunSessionSyncStatus { localOnly, synced, syncSkipped, syncFailed }

class RunSession {
  const RunSession({
    required this.id,
    required this.startedAt,
    required this.distanceM,
    required this.durationMs,
    required this.sourceSummary,
    required this.points,
    this.averageCadenceSpm,
    this.caloriesKcal,
    this.endedAt,
    this.recordSource = RunSessionRecordSource.appLocal,
    this.captureSource = RunSessionCaptureSource.phoneGps,
    this.externalId,
    this.lastSyncedAt,
    this.syncStatus = RunSessionSyncStatus.localOnly,
    this.recordRaceSummary,
    this.shoeId,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceM;
  final int durationMs;
  final String sourceSummary;
  final List<RunPoint> points;
  final double? averageCadenceSpm;
  final double? caloriesKcal;
  final RunSessionRecordSource recordSource;
  final RunSessionCaptureSource captureSource;
  final String? externalId;
  final DateTime? lastSyncedAt;
  final RunSessionSyncStatus syncStatus;
  final RunSessionRecordRaceSummary? recordRaceSummary;
  final String? shoeId;

  RunSession copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    double? distanceM,
    int? durationMs,
    String? sourceSummary,
    List<RunPoint>? points,
    double? averageCadenceSpm,
    double? caloriesKcal,
    RunSessionRecordSource? recordSource,
    RunSessionCaptureSource? captureSource,
    String? externalId,
    DateTime? lastSyncedAt,
    RunSessionSyncStatus? syncStatus,
    RunSessionRecordRaceSummary? recordRaceSummary,
    String? shoeId,
    bool clearShoeId = false,
  }) {
    return RunSession(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceM: distanceM ?? this.distanceM,
      durationMs: durationMs ?? this.durationMs,
      sourceSummary: sourceSummary ?? this.sourceSummary,
      points: points ?? this.points,
      averageCadenceSpm: averageCadenceSpm ?? this.averageCadenceSpm,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      recordSource: recordSource ?? this.recordSource,
      captureSource: captureSource ?? this.captureSource,
      externalId: externalId ?? this.externalId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      recordRaceSummary: recordRaceSummary ?? this.recordRaceSummary,
      shoeId: clearShoeId ? null : shoeId ?? this.shoeId,
    );
  }

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
      caloriesKcal: (json['caloriesKcal'] as num?)?.toDouble(),
      recordSource: _enumByName(
        RunSessionRecordSource.values,
        json['recordSource'] as String?,
        RunSessionRecordSource.appLocal,
      ),
      captureSource: _enumByName(
        RunSessionCaptureSource.values,
        json['captureSource'] as String?,
        RunSessionCaptureSource.phoneGps,
      ),
      externalId: json['externalId'] as String?,
      lastSyncedAt: json['lastSyncedAt'] == null
          ? null
          : DateTime.parse(json['lastSyncedAt'] as String),
      syncStatus: _enumByName(
        RunSessionSyncStatus.values,
        json['syncStatus'] as String?,
        RunSessionSyncStatus.localOnly,
      ),
      recordRaceSummary:
          (json['recordRaceSummary'] ?? json['ghostSummary']) == null
          ? null
          : RunSessionRecordRaceSummary.fromJson(
              (json['recordRaceSummary'] ?? json['ghostSummary'])
                  as Map<String, dynamic>,
            ),
      shoeId: json['shoeId'] as String?,
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
      'caloriesKcal': caloriesKcal,
      'recordSource': recordSource.name,
      'captureSource': captureSource.name,
      'externalId': externalId,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'recordRaceSummary': recordRaceSummary?.toJson(),
      'shoeId': shoeId,
      'points': points
          .map((RunPoint point) => point.toJson())
          .toList(growable: false),
    };
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null) {
      return fallback;
    }
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}

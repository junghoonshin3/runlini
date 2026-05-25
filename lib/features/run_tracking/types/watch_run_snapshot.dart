enum WatchRunPhase { ready, running, paused, reviewing }

enum WatchRecordRaceStatus { unavailable, ahead, behind, level, offRoute }

class WatchRunSnapshot {
  const WatchRunSnapshot({
    required this.sessionId,
    required this.phase,
    required this.elapsedMs,
    required this.distanceM,
    this.averagePaceSecPerKm,
    this.currentPaceSecPerKm,
    this.heartRateBpm,
    this.caloriesKcal,
    this.recordRaceStatus = WatchRecordRaceStatus.unavailable,
    this.recordRaceTimeGapMs,
    this.phoneConnected = false,
  });

  final String sessionId;
  final WatchRunPhase phase;
  final int elapsedMs;
  final double distanceM;
  final double? averagePaceSecPerKm;
  final double? currentPaceSecPerKm;
  final int? heartRateBpm;
  final double? caloriesKcal;
  final WatchRecordRaceStatus recordRaceStatus;
  final int? recordRaceTimeGapMs;
  final bool phoneConnected;

  factory WatchRunSnapshot.fromJson(Map<String, dynamic> json) {
    return WatchRunSnapshot(
      sessionId: json['sessionId'] as String,
      phase: _enumByName(
        WatchRunPhase.values,
        json['phase'] as String?,
        WatchRunPhase.ready,
      ),
      elapsedMs: json['elapsedMs'] as int,
      distanceM: (json['distanceM'] as num).toDouble(),
      averagePaceSecPerKm: (json['averagePaceSecPerKm'] as num?)?.toDouble(),
      currentPaceSecPerKm: (json['currentPaceSecPerKm'] as num?)?.toDouble(),
      heartRateBpm: (json['heartRateBpm'] as num?)?.round(),
      caloriesKcal: (json['caloriesKcal'] as num?)?.toDouble(),
      recordRaceStatus: _enumByName(
        WatchRecordRaceStatus.values,
        json['recordRaceStatus'] as String?,
        WatchRecordRaceStatus.unavailable,
      ),
      recordRaceTimeGapMs: json['recordRaceTimeGapMs'] as int?,
      phoneConnected: json['phoneConnected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'phase': phase.name,
      'elapsedMs': elapsedMs,
      'distanceM': distanceM,
      'averagePaceSecPerKm': averagePaceSecPerKm,
      'currentPaceSecPerKm': currentPaceSecPerKm,
      'heartRateBpm': heartRateBpm,
      'caloriesKcal': caloriesKcal,
      'recordRaceStatus': recordRaceStatus.name,
      'recordRaceTimeGapMs': recordRaceTimeGapMs,
      'phoneConnected': phoneConnected,
    };
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}

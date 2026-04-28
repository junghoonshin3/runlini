enum WatchRunPhase { ready, running, paused, reviewing }

enum WatchGhostStatus { unavailable, ahead, behind, level, offRoute }

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
    this.ghostStatus = WatchGhostStatus.unavailable,
    this.ghostTimeGapMs,
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
  final WatchGhostStatus ghostStatus;
  final int? ghostTimeGapMs;
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
      ghostStatus: _enumByName(
        WatchGhostStatus.values,
        json['ghostStatus'] as String?,
        WatchGhostStatus.unavailable,
      ),
      ghostTimeGapMs: json['ghostTimeGapMs'] as int?,
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
      'ghostStatus': ghostStatus.name,
      'ghostTimeGapMs': ghostTimeGapMs,
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

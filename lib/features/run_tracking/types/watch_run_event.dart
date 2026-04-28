enum WatchRunEventType { start, pause, resume, stop, lap, ghost, audioCue }

class WatchRunEvent {
  const WatchRunEvent({
    required this.sessionId,
    required this.type,
    required this.elapsedMs,
    required this.createdAt,
    this.message,
    this.lapIndex,
    this.ghostTimeGapMs,
  });

  final String sessionId;
  final WatchRunEventType type;
  final int elapsedMs;
  final DateTime createdAt;
  final String? message;
  final int? lapIndex;
  final int? ghostTimeGapMs;

  factory WatchRunEvent.fromJson(Map<String, dynamic> json) {
    return WatchRunEvent(
      sessionId: json['sessionId'] as String,
      type: _enumByName(
        WatchRunEventType.values,
        json['type'] as String?,
        WatchRunEventType.start,
      ),
      elapsedMs: json['elapsedMs'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      message: json['message'] as String?,
      lapIndex: json['lapIndex'] as int?,
      ghostTimeGapMs: json['ghostTimeGapMs'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'type': type.name,
      'elapsedMs': elapsedMs,
      'createdAt': createdAt.toIso8601String(),
      'message': message,
      'lapIndex': lapIndex,
      'ghostTimeGapMs': ghostTimeGapMs,
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

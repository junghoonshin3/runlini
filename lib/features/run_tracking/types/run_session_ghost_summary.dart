enum RunSessionGhostResult { ahead, behind, level, offRoute }

class RunSessionGhostSummary {
  const RunSessionGhostSummary({
    required this.result,
    required this.timeGapMs,
    required this.distanceGapM,
    required this.ghostSessionId,
    required this.ghostLabel,
  });

  final RunSessionGhostResult result;
  final int timeGapMs;
  final double distanceGapM;
  final String ghostSessionId;
  final String ghostLabel;

  factory RunSessionGhostSummary.fromJson(Map<String, dynamic> json) {
    return RunSessionGhostSummary(
      result: RunSessionGhostResult.values.byName(json['result'] as String),
      timeGapMs: json['timeGapMs'] as int,
      distanceGapM: (json['distanceGapM'] as num).toDouble(),
      ghostSessionId: json['ghostSessionId'] as String,
      ghostLabel: json['ghostLabel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'result': result.name,
      'timeGapMs': timeGapMs,
      'distanceGapM': distanceGapM,
      'ghostSessionId': ghostSessionId,
      'ghostLabel': ghostLabel,
    };
  }
}

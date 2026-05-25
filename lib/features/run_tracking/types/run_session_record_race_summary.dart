enum RunSessionRecordRaceResult { ahead, behind, level, offRoute }

class RunSessionRecordRaceSummary {
  const RunSessionRecordRaceSummary({
    required this.result,
    required this.timeGapMs,
    required this.distanceGapM,
    required this.recordRaceSessionId,
    required this.recordRaceLabel,
  });

  final RunSessionRecordRaceResult result;
  final int timeGapMs;
  final double distanceGapM;
  final String recordRaceSessionId;
  final String recordRaceLabel;

  factory RunSessionRecordRaceSummary.fromJson(Map<String, dynamic> json) {
    return RunSessionRecordRaceSummary(
      result: RunSessionRecordRaceResult.values.byName(
        json['result'] as String,
      ),
      timeGapMs: json['timeGapMs'] as int,
      distanceGapM: (json['distanceGapM'] as num).toDouble(),
      recordRaceSessionId:
          (json['recordRaceSessionId'] ?? json['ghostSessionId']) as String,
      recordRaceLabel:
          (json['recordRaceLabel'] ?? json['ghostLabel']) as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'result': result.name,
      'timeGapMs': timeGapMs,
      'distanceGapM': distanceGapM,
      'recordRaceSessionId': recordRaceSessionId,
      'recordRaceLabel': recordRaceLabel,
    };
  }
}

import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';

RunSessionRecordRaceSummary? runSessionRecordRaceSummaryFromFrame(
  RecordRaceFrame? frame,
  RunSession? recordRaceSession,
) {
  if (frame == null ||
      recordRaceSession == null ||
      frame.status == RecordRaceStatus.unavailable) {
    return null;
  }

  return RunSessionRecordRaceSummary(
    result: switch (frame.status) {
      RecordRaceStatus.ahead => RunSessionRecordRaceResult.ahead,
      RecordRaceStatus.behind => RunSessionRecordRaceResult.behind,
      RecordRaceStatus.level => RunSessionRecordRaceResult.level,
      RecordRaceStatus.offRoute => RunSessionRecordRaceResult.offRoute,
      RecordRaceStatus.unavailable => RunSessionRecordRaceResult.level,
    },
    timeGapMs: frame.timeGapMs,
    distanceGapM: frame.distanceGapM,
    recordRaceSessionId: recordRaceSession.id,
    recordRaceLabel: recordRaceSession.sourceSummary,
  );
}

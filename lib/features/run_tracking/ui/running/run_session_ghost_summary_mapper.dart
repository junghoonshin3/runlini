import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

RunSessionGhostSummary? runSessionGhostSummaryFromFrame(
  GhostRaceFrame? frame,
  RunSession? ghostSession,
) {
  if (frame == null ||
      ghostSession == null ||
      frame.status == GhostRaceStatus.unavailable) {
    return null;
  }

  return RunSessionGhostSummary(
    result: switch (frame.status) {
      GhostRaceStatus.ahead => RunSessionGhostResult.ahead,
      GhostRaceStatus.behind => RunSessionGhostResult.behind,
      GhostRaceStatus.level => RunSessionGhostResult.level,
      GhostRaceStatus.offRoute => RunSessionGhostResult.offRoute,
      GhostRaceStatus.unavailable => RunSessionGhostResult.level,
    },
    timeGapMs: frame.timeGapMs,
    distanceGapM: frame.distanceGapM,
    ghostSessionId: ghostSession.id,
    ghostLabel: ghostSession.sourceSummary,
  );
}

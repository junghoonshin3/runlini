// 오늘 시작 전 추천할 기록 레이스 후보를 고르는 서비스
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

enum RunRecordRaceRecommendationReason { sameWeekday, latest }

class RunRecordRaceRecommendation {
  const RunRecordRaceRecommendation({
    required this.summary,
    required this.reason,
  });

  final RunSessionSummary summary;
  final RunRecordRaceRecommendationReason reason;
}

class RunRecordRaceRecommendationService {
  const RunRecordRaceRecommendationService();

  RunRecordRaceRecommendation? recommend({
    required List<RunSessionSummary> summaries,
    required DateTime now,
  }) {
    final candidates = summaries.where(_isRunnableRecordRace).toList()
      ..sort((left, right) => right.startedAt.compareTo(left.startedAt));
    if (candidates.isEmpty) {
      return null;
    }

    for (final candidate in candidates) {
      if (candidate.startedAt.weekday == now.weekday) {
        return RunRecordRaceRecommendation(
          summary: candidate,
          reason: RunRecordRaceRecommendationReason.sameWeekday,
        );
      }
    }

    return RunRecordRaceRecommendation(
      summary: candidates.first,
      reason: RunRecordRaceRecommendationReason.latest,
    );
  }

  bool _isRunnableRecordRace(RunSessionSummary summary) {
    return summary.distanceM > 0 &&
        summary.durationMs > 0 &&
        summary.pointCount >= 2 &&
        summary.averagePaceSecPerKm.isFinite &&
        summary.averagePaceSecPerKm > 0;
  }
}

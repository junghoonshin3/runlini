// 오늘의 기록 레이스 추천 후보 계산을 검증한다
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_record_race_recommendation_service.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

void main() {
  test('prefers the latest runnable session from the same weekday', () {
    const service = RunRecordRaceRecommendationService();
    final recommendation = service.recommend(
      now: DateTime(2026, 5, 18),
      summaries: [
        _summary(id: 'latest-other-day', startedAt: DateTime(2026, 5, 17)),
        _summary(id: 'same-weekday', startedAt: DateTime(2026, 5, 11)),
      ],
    );

    expect(recommendation, isNotNull);
    expect(recommendation!.summary.id, 'same-weekday');
    expect(
      recommendation.reason,
      RunRecordRaceRecommendationReason.sameWeekday,
    );
  });

  test('falls back to the latest runnable session', () {
    const service = RunRecordRaceRecommendationService();
    final recommendation = service.recommend(
      now: DateTime(2026, 5, 18),
      summaries: [
        _summary(id: 'latest', startedAt: DateTime(2026, 5, 17)),
        _summary(id: 'older', startedAt: DateTime(2026, 5, 16)),
      ],
    );

    expect(recommendation, isNotNull);
    expect(recommendation!.summary.id, 'latest');
    expect(recommendation.reason, RunRecordRaceRecommendationReason.latest);
  });

  test('ignores sessions without enough route points', () {
    const service = RunRecordRaceRecommendationService();
    final recommendation = service.recommend(
      now: DateTime(2026, 5, 18),
      summaries: [
        _summary(
          id: 'no-route',
          startedAt: DateTime(2026, 5, 18),
          pointCount: 1,
        ),
      ],
    );

    expect(recommendation, isNull);
  });
}

RunSessionSummary _summary({
  required String id,
  required DateTime startedAt,
  int pointCount = 2,
}) {
  return RunSessionSummary(
    id: id,
    startedAt: startedAt,
    distanceM: 3000,
    durationMs: 1080000,
    averagePaceSecPerKm: 360,
    sourceSummary: 'device:gps',
    recordSource: RunSessionRecordSource.appLocal,
    captureSource: RunSessionCaptureSource.phoneGps,
    syncStatus: RunSessionSyncStatus.localOnly,
    pointCount: pointCount,
  );
}

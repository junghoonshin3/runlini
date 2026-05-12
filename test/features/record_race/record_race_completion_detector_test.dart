import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/record_race/service/record_race_completion_detector.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';

void main() {
  const detector = RecordRaceCompletionDetector();

  test('requires two consecutive finish candidates', () {
    final first = detector.evaluate(
      frame: _frame(routeProgress: 0.99, distanceToFinishM: 12),
      runnerDistanceM: 950,
      previousCandidateCount: 0,
    );
    expect(first.isCandidate, isTrue);
    expect(first.isComplete, isFalse);

    final second = detector.evaluate(
      frame: _frame(routeProgress: 0.99, distanceToFinishM: 10),
      runnerDistanceM: 980,
      previousCandidateCount: first.candidateCount,
    );
    expect(second.isComplete, isTrue);
  });

  test('does not complete off route', () {
    final decision = detector.evaluate(
      frame: _frame(
        status: RecordRaceStatus.offRoute,
        isOffRoute: true,
        routeProgress: 0.99,
        distanceToFinishM: 8,
        distanceFromRouteM: 40,
      ),
      runnerDistanceM: 980,
      previousCandidateCount: 1,
    );

    expect(decision.isCandidate, isFalse);
    expect(decision.candidateCount, 0);
  });

  test('does not complete before recordRace start is confirmed', () {
    final decision = detector.evaluate(
      frame: _frame(
        routeProgress: 0.99,
        distanceToFinishM: 8,
        distanceToFinishPointM: 5,
        startConfirmed: false,
      ),
      runnerDistanceM: 980,
      previousCandidateCount: 1,
    );

    expect(decision.isCandidate, isFalse);
    expect(decision.isComplete, isFalse);
  });

  test('blocks loop false finish before enough runner distance', () {
    final decision = detector.evaluate(
      frame: _frame(
        routeProgress: 0.99,
        distanceToFinishM: 8,
        distanceToFinishPointM: 5,
      ),
      runnerDistanceM: 300,
      previousCandidateCount: 1,
    );

    expect(decision.isCandidate, isFalse);
  });

  test(
    'blocks finish point proximity when runner distance is below 90 percent',
    () {
      final decision = detector.evaluate(
        frame: _frame(
          routeProgress: 0.99,
          distanceToFinishM: 12,
          distanceToFinishPointM: 18,
          totalRouteDistanceM: 1481,
        ),
        runnerDistanceM: 704,
        previousCandidateCount: 1,
      );

      expect(decision.isCandidate, isFalse);
      expect(decision.isComplete, isFalse);
    },
  );

  test('accepts final point radius near the last route window', () {
    final decision = detector.evaluate(
      frame: _frame(
        routeProgress: 0.94,
        distanceToFinishM: 90,
        distanceToFinishPointM: 12,
      ),
      runnerDistanceM: 950,
      previousCandidateCount: 1,
    );

    expect(decision.isComplete, isTrue);
  });
}

RecordRaceFrame _frame({
  RecordRaceStatus status = RecordRaceStatus.ahead,
  bool isOffRoute = false,
  double routeProgress = 0.5,
  double distanceToFinishM = 500,
  double distanceFromRouteM = 5,
  double totalRouteDistanceM = 1000,
  double distanceToFinishPointM = 500,
  bool startConfirmed = true,
}) {
  return RecordRaceFrame(
    status: status,
    timeGapMs: 10000,
    distanceGapM: 30,
    recordRaceMarkerPoint: null,
    isOffRoute: isOffRoute,
    routeProgress: routeProgress,
    distanceToFinishM: distanceToFinishM,
    distanceFromRouteM: distanceFromRouteM,
    totalRouteDistanceM: totalRouteDistanceM,
    distanceToFinishPointM: distanceToFinishPointM,
    startConfirmed: startConfirmed,
  );
}

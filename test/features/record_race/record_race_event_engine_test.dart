// 기록 레이스 이벤트 엔진의 안정화와 중복 억제 정책을 검증한다
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/record_race/service/record_race_event_engine.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';

void main() {
  test('off-route under 10 seconds does not emit then emits once', () {
    final engine = RecordRaceEventEngine();
    final start = DateTime(2026, 5, 8, 7);

    expect(
      engine.eventsFor(
        sessionId: 'run-a',
        frame: _frame(RecordRaceStatus.offRoute),
        isRunning: true,
        now: start,
      ),
      isEmpty,
    );
    expect(
      engine.eventsFor(
        sessionId: 'run-a',
        frame: _frame(RecordRaceStatus.offRoute),
        isRunning: true,
        now: start.add(const Duration(seconds: 9)),
      ),
      isEmpty,
    );

    final emitted = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.offRoute),
      isRunning: true,
      now: start.add(const Duration(seconds: 10)),
    );
    final duplicate = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.offRoute),
      isRunning: true,
      now: start.add(const Duration(seconds: 20)),
    );

    expect(emitted.map((event) => event.type), [RecordRaceEventType.offRoute]);
    expect(duplicate, isEmpty);
  });

  test('return-to-route emits once after stable recovery', () {
    final engine = RecordRaceEventEngine();
    final start = DateTime(2026, 5, 8, 7);

    engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.offRoute),
      isRunning: true,
      now: start,
    );
    engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.offRoute),
      isRunning: true,
      now: start.add(const Duration(seconds: 10)),
    );

    expect(
      engine.eventsFor(
        sessionId: 'run-a',
        frame: _frame(RecordRaceStatus.ahead),
        isRunning: true,
        now: start.add(const Duration(seconds: 15)),
      ),
      isEmpty,
    );

    final emitted = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.ahead),
      isRunning: true,
      now: start.add(const Duration(seconds: 25)),
    );

    expect(emitted.map((event) => event.type), [
      RecordRaceEventType.backOnRoute,
    ]);
  });

  test('ahead and behind transitions emit after 15 stable seconds', () {
    final engine = RecordRaceEventEngine();
    final start = DateTime(2026, 5, 8, 7);

    engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.behind),
      isRunning: true,
      now: start,
    );
    expect(
      engine.eventsFor(
        sessionId: 'run-a',
        frame: _frame(RecordRaceStatus.behind),
        isRunning: true,
        now: start.add(const Duration(seconds: 15)),
      ),
      isEmpty,
    );

    engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.ahead, gapMs: 12000),
      isRunning: true,
      now: start.add(const Duration(seconds: 20)),
    );
    final emitted = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.ahead, gapMs: 12000),
      isRunning: true,
      now: start.add(const Duration(seconds: 35)),
    );

    expect(emitted.map((event) => event.type), [RecordRaceEventType.overtake]);
  });

  test('last stretch and completion events emit once', () {
    final engine = RecordRaceEventEngine();
    final start = DateTime(2026, 5, 8, 7);

    final last500 = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.ahead, distanceToFinishM: 500),
      isRunning: true,
      now: start,
    );
    final last200 = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.ahead, distanceToFinishM: 200),
      isRunning: true,
      now: start.add(const Duration(seconds: 1)),
    );
    final completed = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.ahead, distanceToFinishM: 20),
      isRunning: true,
      now: start.add(const Duration(seconds: 2)),
      completionPending: true,
    );
    final duplicate = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.ahead, distanceToFinishM: 10),
      isRunning: true,
      now: start.add(const Duration(seconds: 3)),
      completionPending: true,
    );

    expect(last500.map((event) => event.type), [RecordRaceEventType.last500m]);
    expect(last200.map((event) => event.type), [RecordRaceEventType.last200m]);
    expect(completed.map((event) => event.type), [
      RecordRaceEventType.completed,
    ]);
    expect(duplicate, isEmpty);
  });

  test('recordRace state events are suppressed before start is confirmed', () {
    final engine = RecordRaceEventEngine();
    final start = DateTime(2026, 5, 8, 7);

    engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.offRoute, startConfirmed: false),
      isRunning: true,
      now: start,
    );

    final emitted = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(RecordRaceStatus.offRoute, startConfirmed: false),
      isRunning: true,
      now: start.add(const Duration(seconds: 10)),
    );

    expect(emitted, isEmpty);
  });

  test('completion is suppressed before start is confirmed', () {
    final engine = RecordRaceEventEngine();

    final emitted = engine.eventsFor(
      sessionId: 'run-a',
      frame: _frame(
        RecordRaceStatus.ahead,
        distanceToFinishM: 20,
        startConfirmed: false,
      ),
      isRunning: true,
      now: DateTime(2026, 5, 8, 7),
      completionPending: true,
    );

    expect(
      emitted.map((event) => event.type),
      isNot(contains(RecordRaceEventType.completed)),
    );
  });

  test('events are suppressed when not running', () {
    final engine = RecordRaceEventEngine();

    expect(
      engine.eventsFor(
        sessionId: 'run-a',
        frame: _frame(RecordRaceStatus.offRoute),
        isRunning: false,
        now: DateTime(2026, 5, 8, 7),
      ),
      isEmpty,
    );
  });
}

RecordRaceFrame _frame(
  RecordRaceStatus status, {
  int gapMs = 12000,
  double distanceToFinishM = 600,
  bool startConfirmed = true,
}) {
  return RecordRaceFrame(
    status: status,
    timeGapMs: gapMs,
    distanceGapM: 24,
    recordRaceMarkerPoint: const MapCoordinate(latitude: 37, longitude: 127),
    isOffRoute: status == RecordRaceStatus.offRoute,
    routeProgress: 0.7,
    distanceToFinishM: distanceToFinishM,
    distanceFromRouteM: status == RecordRaceStatus.offRoute ? 50 : 4,
    totalRouteDistanceM: 1200,
    distanceToFinishPointM: distanceToFinishM,
    startConfirmed: startConfirmed,
  );
}

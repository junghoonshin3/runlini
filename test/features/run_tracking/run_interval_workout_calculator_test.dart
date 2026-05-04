import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_interval_formatters.dart';

void main() {
  const calculator = RunIntervalWorkoutCalculator();

  test('calculates warmup, work, recovery, and cooldown by time', () {
    const workout = RunIntervalWorkout(
      enabled: true,
      warmup: RunIntervalTarget.time(5000),
      work: RunIntervalTarget.time(1000),
      recovery: RunIntervalTarget.time(2000),
      repeatCount: 2,
      cooldown: RunIntervalTarget.time(3000),
    );

    expect(
      formatRunIntervalStepLabel(
        calculator
            .calculate(workout: workout, elapsedMs: 0, distanceM: 0)!
            .step,
      ),
      '워밍업',
    );
    expect(
      formatRunIntervalStepLabel(
        calculator
            .calculate(workout: workout, elapsedMs: 5200, distanceM: 0)!
            .step,
      ),
      '질주 1/2',
    );
    expect(
      formatRunIntervalStepLabel(
        calculator
            .calculate(workout: workout, elapsedMs: 6500, distanceM: 0)!
            .step,
      ),
      '휴식 1/2',
    );
    expect(
      formatRunIntervalStepLabel(
        calculator
            .calculate(workout: workout, elapsedMs: 11000, distanceM: 0)!
            .step,
      ),
      '쿨다운',
    );
  });

  test('uses distance targets and skips disabled steps', () {
    const workout = RunIntervalWorkout(
      enabled: true,
      warmup: RunIntervalTarget.skip(),
      work: RunIntervalTarget.distance(400),
      recovery: RunIntervalTarget.distance(200),
      repeatCount: 1,
      cooldown: RunIntervalTarget.skip(),
    );

    final work = calculator.calculate(
      workout: workout,
      elapsedMs: 30000,
      distanceM: 250,
    )!;
    expect(formatRunIntervalStepLabel(work.step), '질주 1/1');
    expect(work.remainingM, 150);

    final recovery = calculator.calculate(
      workout: workout,
      elapsedMs: 60000,
      distanceM: 450,
    )!;
    expect(formatRunIntervalStepLabel(recovery.step), '휴식 1/1');
    expect(recovery.remainingM, 150);
  });

  test('returns null when interval is disabled', () {
    expect(
      calculator.calculate(
        workout: const RunIntervalWorkout(),
        elapsedMs: 0,
        distanceM: 0,
      ),
      isNull,
    );
  });

  test('round trips workout json', () {
    const workout = RunIntervalWorkout(
      enabled: true,
      warmup: RunIntervalTarget.open(),
      work: RunIntervalTarget.time(60000),
      recovery: RunIntervalTarget.distance(200),
      repeatCount: 6,
      cooldown: RunIntervalTarget.skip(),
    );

    final restored = RunIntervalWorkout.fromJson(workout.toJson());

    expect(restored.enabled, isTrue);
    expect(restored.warmup.type, RunIntervalTargetType.open);
    expect(restored.recovery.distanceM, 200);
    expect(restored.repeatCount, 6);
    expect(restored.cooldown.type, RunIntervalTargetType.skip);
  });
}

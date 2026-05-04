import 'dart:math' as math;

import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';

class RunIntervalWorkoutCalculator {
  const RunIntervalWorkoutCalculator();

  RunIntervalFrame? calculate({
    required RunIntervalWorkout workout,
    required int elapsedMs,
    required double distanceM,
    int manualAdvanceCount = 0,
  }) {
    if (!workout.enabled) {
      return null;
    }
    final steps = buildSteps(workout);
    if (steps.isEmpty) {
      return null;
    }

    var stepStartMs = 0;
    var stepStartDistanceM = 0.0;
    var openStepsAdvanced = 0;
    for (var index = 0; index < steps.length; index += 1) {
      final step = steps[index];
      final progress = _progressFor(
        step.target,
        elapsedMs - stepStartMs,
        distanceM - stepStartDistanceM,
      );
      if (step.target.type == RunIntervalTargetType.open) {
        if (openStepsAdvanced < manualAdvanceCount) {
          openStepsAdvanced += 1;
          stepStartMs = elapsedMs;
          stepStartDistanceM = distanceM;
          continue;
        }
        return _frame(steps, index, progress);
      }
      if (progress.isComplete) {
        stepStartMs += progress.targetDurationMs ?? 0;
        stepStartDistanceM += progress.targetDistanceM ?? 0;
        continue;
      }
      return _frame(steps, index, progress);
    }

    return RunIntervalFrame(
      step: RunIntervalStep(
        kind: RunIntervalStepKind.finished,
        target: const RunIntervalTarget.skip(),
        repeatIndex: null,
        repeatCount: workout.repeatCount,
      ),
      nextStep: null,
      remainingMs: 0,
      remainingM: null,
      progress: 1,
    );
  }

  List<RunIntervalStep> buildSteps(RunIntervalWorkout workout) {
    final steps = <RunIntervalStep>[];
    _addStep(steps, RunIntervalStepKind.warmup, workout.warmup, null, workout);
    for (var repeat = 1; repeat <= workout.repeatCount; repeat += 1) {
      _addStep(steps, RunIntervalStepKind.work, workout.work, repeat, workout);
      _addStep(
        steps,
        RunIntervalStepKind.recovery,
        workout.recovery,
        repeat,
        workout,
      );
    }
    _addStep(
      steps,
      RunIntervalStepKind.cooldown,
      workout.cooldown,
      null,
      workout,
    );
    return steps;
  }

  void _addStep(
    List<RunIntervalStep> steps,
    RunIntervalStepKind kind,
    RunIntervalTarget target,
    int? repeatIndex,
    RunIntervalWorkout workout,
  ) {
    if (target.type == RunIntervalTargetType.skip) {
      return;
    }
    steps.add(
      RunIntervalStep(
        kind: kind,
        target: target,
        repeatIndex: repeatIndex,
        repeatCount: workout.repeatCount,
      ),
    );
  }

  RunIntervalFrame _frame(
    List<RunIntervalStep> steps,
    int index,
    _IntervalProgress progress,
  ) {
    return RunIntervalFrame(
      step: steps[index],
      nextStep: index + 1 < steps.length ? steps[index + 1] : null,
      remainingMs: progress.remainingMs,
      remainingM: progress.remainingM,
      progress: progress.ratio,
    );
  }

  _IntervalProgress _progressFor(
    RunIntervalTarget target,
    int elapsedMs,
    double distanceM,
  ) {
    switch (target.type) {
      case RunIntervalTargetType.time:
        final targetMs = math.max(1, target.durationMs ?? 1);
        final remaining = math.max(0, targetMs - elapsedMs);
        return _IntervalProgress(
          isComplete: elapsedMs >= targetMs,
          remainingMs: remaining,
          ratio: (elapsedMs / targetMs).clamp(0.0, 1.0),
          targetDurationMs: targetMs,
        );
      case RunIntervalTargetType.distance:
        final targetM = math.max(1.0, target.distanceM ?? 1.0);
        final remaining = math.max(0.0, targetM - distanceM);
        return _IntervalProgress(
          isComplete: distanceM >= targetM,
          remainingM: remaining,
          ratio: (distanceM / targetM).clamp(0.0, 1.0),
          targetDistanceM: targetM,
        );
      case RunIntervalTargetType.open:
        return const _IntervalProgress(isComplete: false, ratio: 0);
      case RunIntervalTargetType.skip:
        return const _IntervalProgress(isComplete: true, ratio: 1);
    }
  }
}

class RunIntervalStep {
  const RunIntervalStep({
    required this.kind,
    required this.target,
    required this.repeatIndex,
    required this.repeatCount,
  });

  final RunIntervalStepKind kind;
  final RunIntervalTarget target;
  final int? repeatIndex;
  final int repeatCount;
}

class RunIntervalFrame {
  const RunIntervalFrame({
    required this.step,
    required this.nextStep,
    required this.remainingMs,
    required this.remainingM,
    required this.progress,
  });

  final RunIntervalStep step;
  final RunIntervalStep? nextStep;
  final int? remainingMs;
  final double? remainingM;
  final double progress;
}

class _IntervalProgress {
  const _IntervalProgress({
    required this.isComplete,
    required this.ratio,
    this.remainingMs,
    this.remainingM,
    this.targetDurationMs,
    this.targetDistanceM,
  });

  final bool isComplete;
  final double ratio;
  final int? remainingMs;
  final double? remainingM;
  final int? targetDurationMs;
  final double? targetDistanceM;
}

import 'dart:math' as math;

import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';

String formatRunIntervalStepLabel(RunIntervalStep step) {
  final base = switch (step.kind) {
    RunIntervalStepKind.warmup => '워밍업',
    RunIntervalStepKind.work => '질주',
    RunIntervalStepKind.recovery => '휴식',
    RunIntervalStepKind.cooldown => '쿨다운',
    RunIntervalStepKind.finished => '완료',
  };
  if (step.repeatIndex == null) {
    return base;
  }
  return '$base ${step.repeatIndex}/${step.repeatCount}';
}

String formatRunIntervalShortStep(RunIntervalStep? step) {
  if (step == null) {
    return '끝';
  }
  return switch (step.kind) {
    RunIntervalStepKind.warmup => '워밍업',
    RunIntervalStepKind.work => '질주',
    RunIntervalStepKind.recovery => '휴식',
    RunIntervalStepKind.cooldown => '쿨다운',
    RunIntervalStepKind.finished => '완료',
  };
}

String formatRunIntervalRemaining(RunIntervalFrame frame) {
  final remainingM = frame.remainingM;
  if (remainingM != null) {
    if (remainingM >= 1000) {
      return '남은 ${(remainingM / 1000).toStringAsFixed(1)}km';
    }
    return '남은 ${remainingM.round()}m';
  }
  final remainingMs = frame.remainingMs;
  if (remainingMs == null) {
    return '직접 넘기기';
  }
  return '남은 ${formatRunIntervalDuration(remainingMs)}';
}

String formatRunIntervalTarget(RunIntervalTarget target) {
  return switch (target.type) {
    RunIntervalTargetType.time => formatRunIntervalDuration(
      target.durationMs ?? 0,
    ),
    RunIntervalTargetType.distance => _distance(target.distanceM ?? 0),
    RunIntervalTargetType.open => '오픈',
    RunIntervalTargetType.skip => '끄기',
  };
}

String formatRunIntervalDuration(int durationMs) {
  final totalSeconds = math.max(0, (durationMs / 1000).round());
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (minutes <= 0) {
    return '$seconds초';
  }
  if (seconds == 0) {
    return '$minutes분';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String _distance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
  return '${meters.round()}m';
}

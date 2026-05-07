import 'dart:math' as math;

import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';

class RunVoiceCueFormatter {
  const RunVoiceCueFormatter._();

  static String ghostStart() => '고스트런 시작';

  static String kilometerSummary({
    required int kilometer,
    required double? averagePaceSecPerKm,
    required int elapsedMs,
    int? ghostGapMs,
  }) {
    final parts = <String>['$kilometer킬로미터'];
    final pace = paceSpeech(averagePaceSecPerKm);
    if (pace != null) {
      parts.add('평균 페이스 $pace');
    }
    final elapsed = elapsedSpeech(elapsedMs);
    if (elapsed != null) {
      parts.add('시간 $elapsed');
    }
    final ghostGap = ghostGapSpeech(ghostGapMs);
    if (ghostGap != null) {
      parts.add(ghostGap);
    }
    return parts.join(', ');
  }

  static String intervalStepLabel(RunIntervalStep step) {
    final base = switch (step.kind) {
      RunIntervalStepKind.warmup => '워밍업',
      RunIntervalStepKind.work => '질주',
      RunIntervalStepKind.recovery => '휴식',
      RunIntervalStepKind.cooldown => '쿨다운',
      RunIntervalStepKind.finished => '완료',
    };
    final repeatIndex = step.repeatIndex;
    if (repeatIndex == null) {
      return base;
    }
    return '$base $repeatIndex/${step.repeatCount}';
  }

  static String? paceSpeech(double? paceSecPerKm) {
    final pace = paceSecPerKm?.takeIfFinitePositive();
    if (pace == null) {
      return null;
    }
    final totalSeconds = pace.round().clamp(1, 24 * 60 * 60).toInt();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) {
      return '$minutes분';
    }
    return '$minutes분 $seconds초';
  }

  static String? elapsedSpeech(int elapsedMs) {
    if (elapsedMs <= 0) {
      return null;
    }
    final totalSeconds = math.max(1, elapsedMs ~/ 1000);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours시간');
    }
    if (minutes > 0) {
      parts.add('$minutes분');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds초');
    }
    return parts.join(' ');
  }

  static String? ghostGapSpeech(int? gapMs) {
    if (gapMs == null || gapMs == 0) {
      return null;
    }
    final gap = _gapSpeech(gapMs);
    return gapMs > 0 ? '고스트보다 $gap 앞서요' : '고스트보다 $gap 뒤처져요';
  }

  static String ghostCompletion(RunSessionGhostSummary summary) {
    final gapMs = summary.timeGapMs;
    if (gapMs == 0 || summary.result == RunSessionGhostResult.level) {
      return '고스트 코스 완료, 거의 같아요';
    }
    final gap = _gapSpeech(gapMs);
    return gapMs > 0 ? '고스트 코스 완료, $gap 빨랐어요' : '고스트 코스 완료, $gap 늦었어요';
  }

  static String _gapSpeech(int gapMs) {
    final totalSeconds = math.max(1, gapMs.abs() ~/ 1000);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes <= 0) {
      return '$seconds초';
    }
    if (seconds == 0) {
      return '$minutes분';
    }
    return '$minutes분 $seconds초';
  }
}

extension on double {
  double? takeIfFinitePositive() {
    if (!isFinite || this <= 0) {
      return null;
    }
    return this;
  }
}

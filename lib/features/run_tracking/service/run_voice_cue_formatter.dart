import 'dart:math' as math;

import 'package:runlini/features/run_tracking/service/run_interval_workout_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';

class RunVoiceCueFormatter {
  const RunVoiceCueFormatter._();

  static String recordRaceStart() => '기록 레이스 시작';

  static String kilometerSummary({
    required int kilometer,
    required double? averagePaceSecPerKm,
    required int elapsedMs,
    int? recordRaceGapMs,
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
    final recordRaceGap = recordRaceGapSpeech(recordRaceGapMs);
    if (recordRaceGap != null) {
      parts.add(recordRaceGap);
    }
    return parts.join('. ');
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

  static String? recordRaceGapSpeech(int? gapMs) {
    if (gapMs == null || gapMs == 0) {
      return null;
    }
    final gap = _gapSpeech(gapMs);
    return gapMs > 0 ? '기록 레이스보다 $gap 앞서고 있어요' : '기록 레이스보다 $gap 뒤처지고 있어요';
  }

  static String recordRaceCompletion(RunSessionRecordRaceSummary summary) {
    if (summary.result == RunSessionRecordRaceResult.level) {
      return '기록 레이스 코스 완료. 거의 같아요';
    }
    return recordRaceCompletionFromGap(summary.timeGapMs);
  }

  static String recordRaceCompletionFromGap(int? gapMs) {
    if (gapMs == null) {
      return '기록 레이스 코스 완료';
    }
    if (gapMs == 0) {
      return '기록 레이스 코스 완료. 거의 같아요';
    }
    final gap = _gapSpeech(gapMs);
    return gapMs > 0
        ? '기록 레이스 코스 완료. 기록 레이스보다 $gap 빨랐어요'
        : '기록 레이스 코스 완료. 기록 레이스보다 $gap 늦었어요';
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

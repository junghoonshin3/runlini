import 'dart:math' as math;

import 'package:runlini/features/record_race/types/record_race_frame.dart';

String formatRecordRaceStatus(RecordRaceStatus status) {
  switch (status) {
    case RecordRaceStatus.ahead:
      return '이기는 중';
    case RecordRaceStatus.behind:
      return '따라가는 중';
    case RecordRaceStatus.level:
      return '접전';
    case RecordRaceStatus.offRoute:
      return '경로 이탈';
    case RecordRaceStatus.unavailable:
      return '';
  }
}

String formatRecordRaceTimeGap(int timeGapMs) {
  final totalSeconds = timeGapMs.abs() ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (totalSeconds == 0) {
    return '0:00';
  }

  final sign = timeGapMs > 0
      ? '+'
      : timeGapMs < 0
      ? '-'
      : '';
  return '$sign$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatRecordRaceDistanceGap(double distanceGapM) {
  final roundedMeters = math.max(0, distanceGapM.abs().round());
  if (roundedMeters == 0) {
    return '기록 레이스와 같은 위치';
  }

  final direction = distanceGapM > 0 ? '뒤' : '앞';
  return '기록 레이스 ${roundedMeters}m $direction';
}

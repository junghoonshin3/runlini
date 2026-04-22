import 'dart:math' as math;

import 'package:runlini/features/ghost_racer/types/ghost_race_frame.dart';

String formatGhostRaceStatus(GhostRaceStatus status) {
  switch (status) {
    case GhostRaceStatus.ahead:
      return 'AHEAD';
    case GhostRaceStatus.behind:
      return 'BEHIND';
    case GhostRaceStatus.level:
      return 'LEVEL';
    case GhostRaceStatus.offRoute:
      return '경로 이탈';
    case GhostRaceStatus.unavailable:
      return '';
  }
}

String formatGhostRaceTimeGap(int timeGapMs) {
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

String formatGhostRaceDistanceGap(double distanceGapM) {
  final roundedMeters = math.max(0, distanceGapM.abs().round());
  if (roundedMeters == 0) {
    return '고스트와 같은 위치';
  }

  final direction = distanceGapM > 0 ? '뒤' : '앞';
  return '고스트 ${roundedMeters}m $direction';
}

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/run_ghost_comparison_builder.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class RunDetailGhostComparisonPresenter {
  const RunDetailGhostComparisonPresenter({
    this.displaySettings = const RunDisplaySettings(),
  });

  final RunDisplaySettings displaySettings;

  Color accentFor(RunSessionGhostResult result) {
    return switch (result) {
      RunSessionGhostResult.ahead => AppColors.voltGreen,
      RunSessionGhostResult.behind => AppColors.electricRed,
      RunSessionGhostResult.level => AppColors.chalk,
      RunSessionGhostResult.offRoute => AppColors.orange,
    };
  }

  String heroLabel(RunSessionGhostSummary summary) {
    if (summary.result == RunSessionGhostResult.offRoute) {
      return '경로를 벗어났어요';
    }
    if (summary.timeGapMs.abs() <= 3000 ||
        summary.result == RunSessionGhostResult.level) {
      return '거의 같아요';
    }
    final duration = _formatKoreanDuration(summary.timeGapMs.abs());
    return summary.timeGapMs > 0 ? '$duration 빨랐어요' : '$duration 늦었어요';
  }

  List<RunDetailGhostComparisonRowData> rowsFor(RunGhostComparison comparison) {
    if (!comparison.hasCourseMetrics) {
      return [
        RunDetailGhostComparisonRowData(
          label: '시간 차이',
          current: '--',
          ghost: '--',
          delta: _formatTimeDelta(comparison.summary.timeGapMs),
          tone: _timeTone(comparison.summary.timeGapMs),
        ),
        RunDetailGhostComparisonRowData(
          label: '거리 차이',
          current: '--',
          ghost: '--',
          delta: _formatDistanceDelta(comparison.summary.distanceGapM),
          tone: _distanceTone(comparison.summary.distanceGapM),
        ),
      ];
    }

    final rows = <RunDetailGhostComparisonRowData>[
      RunDetailGhostComparisonRowData(
        label: '코스 시간',
        current: formatRunElapsed(comparison.currentCourseDurationMs!),
        ghost: formatRunElapsed(comparison.ghostCourseDurationMs!),
        delta: _formatTimeDelta(comparison.summary.timeGapMs),
        tone: _timeTone(comparison.summary.timeGapMs),
      ),
    ];
    _addPaceRow(rows, comparison);
    _addSpeedRow(rows, comparison);
    _addDistanceRow(rows, comparison);
    _addExtraRow(rows, comparison);
    _addCadenceRow(rows, comparison);
    _addElevationRow(rows, comparison);
    return rows;
  }

  void _addPaceRow(
    List<RunDetailGhostComparisonRowData> rows,
    RunGhostComparison comparison,
  ) {
    final current = comparison.currentCoursePaceSecPerKm;
    final ghost = comparison.ghostPaceSecPerKm;
    if (current == null || ghost == null) {
      return;
    }
    final delta = ghost - current;
    rows.add(
      RunDetailGhostComparisonRowData(
        label: '평균 페이스',
        current: formatRunPaceCompact(current, displaySettings),
        ghost: formatRunPaceCompact(ghost, displaySettings),
        delta: _formatPaceDelta(delta),
        tone: _numberTone(delta),
      ),
    );
  }

  void _addSpeedRow(
    List<RunDetailGhostComparisonRowData> rows,
    RunGhostComparison comparison,
  ) {
    final current = comparison.currentCourseSpeedKmh;
    final ghost = comparison.ghostSpeedKmh;
    if (current == null || ghost == null) {
      return;
    }
    final delta = current - ghost;
    rows.add(
      RunDetailGhostComparisonRowData(
        label: '평균 속도',
        current: formatRunSpeed(current, displaySettings),
        ghost: formatRunSpeed(ghost, displaySettings),
        delta: _formatSpeedDelta(delta),
        tone: _numberTone(delta),
      ),
    );
  }

  void _addDistanceRow(
    List<RunDetailGhostComparisonRowData> rows,
    RunGhostComparison comparison,
  ) {
    final current = comparison.currentDistanceM;
    final ghost = comparison.ghostDistanceM;
    if (current == null || ghost == null) {
      return;
    }
    rows.add(
      RunDetailGhostComparisonRowData(
        label: '거리 차이',
        current: formatRunDistance(current, displaySettings, decimals: 2),
        ghost: formatRunDistance(ghost, displaySettings, decimals: 2),
        delta: _formatDistanceDelta(current - ghost),
        tone: _distanceTone(current - ghost),
      ),
    );
  }

  void _addExtraRow(
    List<RunDetailGhostComparisonRowData> rows,
    RunGhostComparison comparison,
  ) {
    if (comparison.extraDurationMs < 15000 && comparison.extraDistanceM < 10) {
      return;
    }
    rows.add(
      RunDetailGhostComparisonRowData(
        label: '추가 기록',
        current: '+${formatRunElapsed(comparison.extraDurationMs)}',
        ghost: '--',
        delta:
            '+${formatRunDistanceGap(comparison.extraDistanceM, displaySettings)}',
        tone: RunDetailGhostComparisonTone.muted,
      ),
    );
  }

  void _addCadenceRow(
    List<RunDetailGhostComparisonRowData> rows,
    RunGhostComparison comparison,
  ) {
    final current = comparison.currentAverageCadenceSpm;
    final ghost = comparison.ghostAverageCadenceSpm;
    if (current == null || ghost == null) {
      return;
    }
    rows.add(
      RunDetailGhostComparisonRowData(
        label: '평균 케이던스',
        current: '${current.round()} spm',
        ghost: '${ghost.round()} spm',
        delta: _formatSignedNumber(current - ghost, suffix: ' spm'),
        tone: _numberTone(current - ghost),
      ),
    );
  }

  void _addElevationRow(
    List<RunDetailGhostComparisonRowData> rows,
    RunGhostComparison comparison,
  ) {
    final current = comparison.currentElevationGainM;
    final ghost = comparison.ghostElevationGainM;
    if (current == null || ghost == null) {
      return;
    }
    rows.add(
      RunDetailGhostComparisonRowData(
        label: '고도',
        current: '${current.round()} m',
        ghost: '${ghost.round()} m',
        delta: _formatSignedNumber(current - ghost, suffix: ' m'),
        tone: RunDetailGhostComparisonTone.neutral,
      ),
    );
  }

  String _formatTimeDelta(int timeGapMs) {
    if (timeGapMs.abs() <= 3000) {
      return '동일';
    }
    final duration = _formatKoreanDuration(timeGapMs.abs());
    return timeGapMs > 0 ? '$duration 빠름' : '$duration 느림';
  }

  String _formatPaceDelta(double secondsPerKm) {
    if (secondsPerKm.abs() <= 1) {
      return '동일';
    }
    final value = _formatPaceDeltaValue(secondsPerKm.abs());
    return secondsPerKm > 0 ? '$value 빠름' : '$value 느림';
  }

  String _formatPaceDeltaValue(double secondsPerKm) {
    final displayPace = paceForDisplay(secondsPerKm, displaySettings).round();
    final minutes = displayPace ~/ 60;
    final seconds = displayPace % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}'
        '/${distanceUnitLabel(displaySettings)}';
  }

  String _formatSpeedDelta(double speedKmh) {
    if (speedKmh.abs() < 0.05) {
      return '동일';
    }
    final sign = speedKmh > 0 ? '+' : '-';
    return '$sign${speedForDisplay(speedKmh.abs(), displaySettings).toStringAsFixed(1)} '
        '${speedUnitLabel(displaySettings)}';
  }

  String _formatDistanceDelta(double distanceM) {
    if (distanceM.abs() < 3) {
      return '동일';
    }
    final sign = distanceM > 0 ? '+' : '-';
    return '$sign${formatRunDistanceGap(distanceM.abs(), displaySettings)}';
  }

  String _formatSignedNumber(double value, {required String suffix}) {
    if (value.abs() < 0.5) {
      return '동일';
    }
    final sign = value > 0 ? '+' : '-';
    return '$sign${value.abs().round()}$suffix';
  }

  String _formatKoreanDuration(int durationMs) {
    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) {
      return '$seconds초';
    }
    if (seconds == 0) {
      return '$minutes분';
    }
    return '$minutes분 $seconds초';
  }
}

class RunDetailGhostComparisonRowData {
  const RunDetailGhostComparisonRowData({
    required this.label,
    required this.current,
    required this.ghost,
    required this.delta,
    required this.tone,
  });

  final String label;
  final String current;
  final String ghost;
  final String delta;
  final RunDetailGhostComparisonTone tone;
}

enum RunDetailGhostComparisonTone { improved, worsened, neutral, muted }

RunDetailGhostComparisonTone _timeTone(int timeGapMs) {
  if (timeGapMs.abs() <= 3000) {
    return RunDetailGhostComparisonTone.neutral;
  }
  return timeGapMs > 0
      ? RunDetailGhostComparisonTone.improved
      : RunDetailGhostComparisonTone.worsened;
}

RunDetailGhostComparisonTone _numberTone(double value) {
  if (value.abs() <= 0.01) {
    return RunDetailGhostComparisonTone.neutral;
  }
  return value > 0
      ? RunDetailGhostComparisonTone.improved
      : RunDetailGhostComparisonTone.worsened;
}

RunDetailGhostComparisonTone _distanceTone(double distanceM) {
  return distanceM.abs() < 3
      ? RunDetailGhostComparisonTone.neutral
      : RunDetailGhostComparisonTone.muted;
}

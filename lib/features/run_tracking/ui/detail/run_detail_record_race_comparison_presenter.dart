import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/run_record_race_comparison_builder.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class RunDetailRecordRaceComparisonPresenter {
  const RunDetailRecordRaceComparisonPresenter({
    this.displaySettings = const RunDisplaySettings(),
  });

  final RunDisplaySettings displaySettings;

  Color accentFor(RunSessionRecordRaceResult result) {
    return switch (result) {
      RunSessionRecordRaceResult.ahead => AppColors.voltGreen,
      RunSessionRecordRaceResult.behind => AppColors.electricRed,
      RunSessionRecordRaceResult.level => AppColors.chalk,
      RunSessionRecordRaceResult.offRoute => AppColors.orange,
    };
  }

  String heroLabel(RunSessionRecordRaceSummary summary) {
    if (summary.result == RunSessionRecordRaceResult.offRoute) {
      return '경로를 벗어났어요';
    }
    if (summary.timeGapMs.abs() <= 3000 ||
        summary.result == RunSessionRecordRaceResult.level) {
      return '거의 같아요';
    }
    final duration = _formatKoreanDuration(summary.timeGapMs.abs());
    return summary.timeGapMs > 0 ? '$duration 빨랐어요' : '$duration 늦었어요';
  }

  List<RunDetailRecordRaceComparisonRowData> rowsFor(
    RunRecordRaceComparison comparison,
  ) {
    if (!comparison.hasCourseMetrics) {
      return [
        RunDetailRecordRaceComparisonRowData(
          label: '시간 차이',
          current: '--',
          recordRace: '--',
          delta: _formatTimeDelta(comparison.summary.timeGapMs),
          tone: _timeTone(comparison.summary.timeGapMs),
        ),
        RunDetailRecordRaceComparisonRowData(
          label: '거리 차이',
          current: '--',
          recordRace: '--',
          delta: _formatDistanceDelta(comparison.summary.distanceGapM),
          tone: _distanceTone(comparison.summary.distanceGapM),
        ),
      ];
    }

    final rows = <RunDetailRecordRaceComparisonRowData>[
      RunDetailRecordRaceComparisonRowData(
        label: '코스 시간',
        current: formatRunElapsed(comparison.currentCourseDurationMs!),
        recordRace: formatRunElapsed(comparison.recordRaceCourseDurationMs!),
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
    List<RunDetailRecordRaceComparisonRowData> rows,
    RunRecordRaceComparison comparison,
  ) {
    final current = comparison.currentCoursePaceSecPerKm;
    final recordRace = comparison.recordRacePaceSecPerKm;
    if (current == null || recordRace == null) {
      return;
    }
    final delta = recordRace - current;
    rows.add(
      RunDetailRecordRaceComparisonRowData(
        label: '평균 페이스',
        current: formatRunPaceCompact(current, displaySettings),
        recordRace: formatRunPaceCompact(recordRace, displaySettings),
        delta: _formatPaceDelta(delta),
        tone: _numberTone(delta),
      ),
    );
  }

  void _addSpeedRow(
    List<RunDetailRecordRaceComparisonRowData> rows,
    RunRecordRaceComparison comparison,
  ) {
    final current = comparison.currentCourseSpeedKmh;
    final recordRace = comparison.recordRaceSpeedKmh;
    if (current == null || recordRace == null) {
      return;
    }
    final delta = current - recordRace;
    rows.add(
      RunDetailRecordRaceComparisonRowData(
        label: '평균 속도',
        current: formatRunSpeed(current, displaySettings),
        recordRace: formatRunSpeed(recordRace, displaySettings),
        delta: _formatSpeedDelta(delta),
        tone: _numberTone(delta),
      ),
    );
  }

  void _addDistanceRow(
    List<RunDetailRecordRaceComparisonRowData> rows,
    RunRecordRaceComparison comparison,
  ) {
    final current = comparison.currentDistanceM;
    final recordRace = comparison.recordRaceDistanceM;
    if (current == null || recordRace == null) {
      return;
    }
    rows.add(
      RunDetailRecordRaceComparisonRowData(
        label: '거리 차이',
        current: formatRunDistance(current, displaySettings, decimals: 2),
        recordRace: formatRunDistance(recordRace, displaySettings, decimals: 2),
        delta: _formatDistanceDelta(current - recordRace),
        tone: _distanceTone(current - recordRace),
      ),
    );
  }

  void _addExtraRow(
    List<RunDetailRecordRaceComparisonRowData> rows,
    RunRecordRaceComparison comparison,
  ) {
    if (comparison.extraDurationMs < 15000 && comparison.extraDistanceM < 10) {
      return;
    }
    rows.add(
      RunDetailRecordRaceComparisonRowData(
        label: '추가 기록',
        current: '+${formatRunElapsed(comparison.extraDurationMs)}',
        recordRace: '--',
        delta:
            '+${formatRunDistanceGap(comparison.extraDistanceM, displaySettings)}',
        tone: RunDetailRecordRaceComparisonTone.muted,
      ),
    );
  }

  void _addCadenceRow(
    List<RunDetailRecordRaceComparisonRowData> rows,
    RunRecordRaceComparison comparison,
  ) {
    final current = comparison.currentAverageCadenceSpm;
    final recordRace = comparison.recordRaceAverageCadenceSpm;
    if (current == null || recordRace == null) {
      return;
    }
    rows.add(
      RunDetailRecordRaceComparisonRowData(
        label: '평균 케이던스',
        current: '${current.round()} spm',
        recordRace: '${recordRace.round()} spm',
        delta: _formatSignedNumber(current - recordRace, suffix: ' spm'),
        tone: _numberTone(current - recordRace),
      ),
    );
  }

  void _addElevationRow(
    List<RunDetailRecordRaceComparisonRowData> rows,
    RunRecordRaceComparison comparison,
  ) {
    final current = comparison.currentElevationGainM;
    final recordRace = comparison.recordRaceElevationGainM;
    if (current == null || recordRace == null) {
      return;
    }
    rows.add(
      RunDetailRecordRaceComparisonRowData(
        label: '고도',
        current: '${current.round()} m',
        recordRace: '${recordRace.round()} m',
        delta: _formatSignedNumber(current - recordRace, suffix: ' m'),
        tone: RunDetailRecordRaceComparisonTone.neutral,
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
    return '${distanceUnitLabel(displaySettings)}당 '
        '${_formatKoreanSeconds(displayPace)}';
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

  String _formatKoreanDuration(int durationMs) =>
      _formatKoreanSeconds((durationMs / 1000).round());

  String _formatKoreanSeconds(int totalSeconds) {
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

class RunDetailRecordRaceComparisonRowData {
  const RunDetailRecordRaceComparisonRowData({
    required this.label,
    required this.current,
    required this.recordRace,
    required this.delta,
    required this.tone,
  });

  final String label;
  final String current;
  final String recordRace;
  final String delta;
  final RunDetailRecordRaceComparisonTone tone;
}

enum RunDetailRecordRaceComparisonTone { improved, worsened, neutral, muted }

RunDetailRecordRaceComparisonTone _timeTone(int timeGapMs) {
  if (timeGapMs.abs() <= 3000) {
    return RunDetailRecordRaceComparisonTone.neutral;
  }
  return timeGapMs > 0
      ? RunDetailRecordRaceComparisonTone.improved
      : RunDetailRecordRaceComparisonTone.worsened;
}

RunDetailRecordRaceComparisonTone _numberTone(double value) {
  if (value.abs() <= 0.01) {
    return RunDetailRecordRaceComparisonTone.neutral;
  }
  return value > 0
      ? RunDetailRecordRaceComparisonTone.improved
      : RunDetailRecordRaceComparisonTone.worsened;
}

RunDetailRecordRaceComparisonTone _distanceTone(double distanceM) {
  return distanceM.abs() < 3
      ? RunDetailRecordRaceComparisonTone.neutral
      : RunDetailRecordRaceComparisonTone.muted;
}

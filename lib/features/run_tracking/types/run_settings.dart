import 'package:flutter/foundation.dart';
import 'package:runlini/features/run_tracking/types/run_history_period.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';

enum RunDistanceUnit { km, mi }

enum RunPaceUnit { minPerKm, minPerMi }

enum RunSpeedUnit { kmh, mph }

enum RunLocationTrackingPreset { batterySaver, balanced, highAccuracy }

const int runCountdownMinSeconds = 3;
const int runCountdownMaxSeconds = 10;
const int defaultRunCountdownSeconds = 3;
const double runBodyWeightMinKg = 20;
const double runBodyWeightMaxKg = 250;
const double defaultWeeklyDistanceGoalM = 20000;
const double defaultMonthlyDistanceGoalM = 80000;
const double defaultYearlyDistanceGoalM = 1000000;
const double runWeeklyDistanceGoalMinM = 1000;
const double runWeeklyDistanceGoalMaxM = 300000;
const double runMonthlyDistanceGoalMinM = 1000;
const double runMonthlyDistanceGoalMaxM = 1500000;
const double runYearlyDistanceGoalMinM = 1000;
const double runYearlyDistanceGoalMaxM = 20000000;
const double runVoiceCueVolumeMin = 0;
const double runVoiceCueVolumeMax = 1;
const double defaultRunVoiceCueVolume = 1;

@immutable
class RunDisplaySettings {
  const RunDisplaySettings({
    this.distanceUnit = RunDistanceUnit.km,
    this.paceUnit = RunPaceUnit.minPerKm,
    this.speedUnit = RunSpeedUnit.kmh,
  });

  final RunDistanceUnit distanceUnit;
  final RunPaceUnit paceUnit;
  final RunSpeedUnit speedUnit;

  RunDisplaySettings copyWith({
    RunDistanceUnit? distanceUnit,
    RunPaceUnit? paceUnit,
    RunSpeedUnit? speedUnit,
  }) {
    return RunDisplaySettings(
      distanceUnit: distanceUnit ?? this.distanceUnit,
      paceUnit: paceUnit ?? this.paceUnit,
      speedUnit: speedUnit ?? this.speedUnit,
    );
  }
}

@immutable
class RunPrivacySettings {
  const RunPrivacySettings({
    this.hideRouteMap = false,
    this.hideStartEndArea = false,
    this.hideHeartRate = false,
    this.hideCalories = false,
  });

  final bool hideRouteMap;
  final bool hideStartEndArea;
  final bool hideHeartRate;
  final bool hideCalories;

  RunPrivacySettings copyWith({
    bool? hideRouteMap,
    bool? hideStartEndArea,
    bool? hideHeartRate,
    bool? hideCalories,
  }) {
    return RunPrivacySettings(
      hideRouteMap: hideRouteMap ?? this.hideRouteMap,
      hideStartEndArea: hideStartEndArea ?? this.hideStartEndArea,
      hideHeartRate: hideHeartRate ?? this.hideHeartRate,
      hideCalories: hideCalories ?? this.hideCalories,
    );
  }
}

@immutable
class RunDistanceGoalSettings {
  const RunDistanceGoalSettings({
    this.weeklyGoalM = defaultWeeklyDistanceGoalM,
    this.monthlyGoalM = defaultMonthlyDistanceGoalM,
    this.yearlyGoalM = defaultYearlyDistanceGoalM,
  });

  final double weeklyGoalM;
  final double monthlyGoalM;
  final double yearlyGoalM;

  double goalFor(RunHistoryPeriod period) {
    return switch (period) {
      RunHistoryPeriod.week => weeklyGoalM,
      RunHistoryPeriod.month => monthlyGoalM,
      RunHistoryPeriod.year => yearlyGoalM,
    };
  }

  RunDistanceGoalSettings copyWith({
    double? weeklyGoalM,
    double? monthlyGoalM,
    double? yearlyGoalM,
  }) {
    return RunDistanceGoalSettings(
      weeklyGoalM: weeklyGoalM ?? this.weeklyGoalM,
      monthlyGoalM: monthlyGoalM ?? this.monthlyGoalM,
      yearlyGoalM: yearlyGoalM ?? this.yearlyGoalM,
    );
  }

  RunDistanceGoalSettings copyWithGoal(
    RunHistoryPeriod period,
    double distanceM,
  ) {
    return switch (period) {
      RunHistoryPeriod.week => copyWith(weeklyGoalM: distanceM),
      RunHistoryPeriod.month => copyWith(monthlyGoalM: distanceM),
      RunHistoryPeriod.year => copyWith(yearlyGoalM: distanceM),
    };
  }
}

@immutable
class RunSettingsState {
  const RunSettingsState({
    this.display = const RunDisplaySettings(),
    this.privacy = const RunPrivacySettings(),
    this.distanceGoals = const RunDistanceGoalSettings(),
    this.countdownSeconds = defaultRunCountdownSeconds,
    this.locationTrackingPreset = RunLocationTrackingPreset.balanced,
    this.autoPauseEnabled = false,
    this.showGhostMarker = false,
    this.intervalWorkout = const RunIntervalWorkout(),
    this.voiceCueEnabled = true,
    this.kmVoiceCueEnabled = true,
    this.ghostVoiceCueEnabled = false,
    this.voiceCueVolume = defaultRunVoiceCueVolume,
    this.bodyWeightKg,
    this.defaultShoeId,
  });

  final RunDisplaySettings display;
  final RunPrivacySettings privacy;
  final RunDistanceGoalSettings distanceGoals;
  final int countdownSeconds;
  final RunLocationTrackingPreset locationTrackingPreset;
  final bool autoPauseEnabled;
  final bool showGhostMarker;
  final RunIntervalWorkout intervalWorkout;
  final bool voiceCueEnabled;
  final bool kmVoiceCueEnabled;
  final bool ghostVoiceCueEnabled;
  final double voiceCueVolume;
  final double? bodyWeightKg;
  final String? defaultShoeId;

  RunSettingsState copyWith({
    RunDisplaySettings? display,
    RunPrivacySettings? privacy,
    RunDistanceGoalSettings? distanceGoals,
    int? countdownSeconds,
    RunLocationTrackingPreset? locationTrackingPreset,
    bool? autoPauseEnabled,
    bool? showGhostMarker,
    RunIntervalWorkout? intervalWorkout,
    bool? voiceCueEnabled,
    bool? kmVoiceCueEnabled,
    bool? ghostVoiceCueEnabled,
    double? voiceCueVolume,
    double? bodyWeightKg,
    bool clearBodyWeightKg = false,
    String? defaultShoeId,
    bool clearDefaultShoeId = false,
  }) {
    return RunSettingsState(
      display: display ?? this.display,
      privacy: privacy ?? this.privacy,
      distanceGoals: distanceGoals ?? this.distanceGoals,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      locationTrackingPreset:
          locationTrackingPreset ?? this.locationTrackingPreset,
      autoPauseEnabled: autoPauseEnabled ?? this.autoPauseEnabled,
      showGhostMarker: showGhostMarker ?? this.showGhostMarker,
      intervalWorkout: intervalWorkout ?? this.intervalWorkout,
      voiceCueEnabled: voiceCueEnabled ?? this.voiceCueEnabled,
      kmVoiceCueEnabled: kmVoiceCueEnabled ?? this.kmVoiceCueEnabled,
      ghostVoiceCueEnabled: ghostVoiceCueEnabled ?? this.ghostVoiceCueEnabled,
      voiceCueVolume: voiceCueVolume ?? this.voiceCueVolume,
      bodyWeightKg: clearBodyWeightKg
          ? null
          : bodyWeightKg ?? this.bodyWeightKg,
      defaultShoeId: clearDefaultShoeId
          ? null
          : defaultShoeId ?? this.defaultShoeId,
    );
  }
}

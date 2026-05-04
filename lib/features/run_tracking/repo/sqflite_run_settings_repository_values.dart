part of 'sqflite_run_settings_repository.dart';

Future<void> _saveValue(DatabaseExecutor db, String key, String value) async {
  await db.insert('app_settings', <String, Object?>{
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

bool _bool(String? value) => value == 'true';

bool _boolWithDefault(String? value, bool fallback) {
  if (value == null) {
    return fallback;
  }
  return value == 'true';
}

int _countdownSeconds(String? value) {
  final parsed = int.tryParse(value ?? '') ?? defaultRunCountdownSeconds;
  return parsed.clamp(runCountdownMinSeconds, runCountdownMaxSeconds).toInt();
}

double? _bodyWeightKg(String? value) {
  final parsed = double.tryParse(value ?? '');
  if (parsed == null ||
      parsed < runBodyWeightMinKg ||
      parsed > runBodyWeightMaxKg) {
    return null;
  }
  return parsed;
}

double _distanceGoalM(
  String? value,
  double fallback,
  double minM,
  double maxM,
) {
  final parsed = double.tryParse(value ?? '');
  if (parsed == null || parsed < minM || parsed > maxM) {
    return fallback;
  }
  return parsed;
}

double _voiceCueVolume(String? value) {
  final parsed = double.tryParse(value ?? '');
  if (parsed == null ||
      parsed < runVoiceCueVolumeMin ||
      parsed > runVoiceCueVolumeMax) {
    return defaultRunVoiceCueVolume;
  }
  return parsed;
}

RunIntervalWorkout _intervalWorkout(String? value) {
  if (value == null || value.trim().isEmpty) {
    return const RunIntervalWorkout();
  }
  try {
    return RunIntervalWorkout.fromJson(
      jsonDecode(value) as Map<String, dynamic>,
    );
  } catch (_) {
    return const RunIntervalWorkout();
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

const _distanceUnitKey = 'distance_unit';
const _paceUnitKey = 'pace_unit';
const _speedUnitKey = 'speed_unit';
const _hideRouteMapKey = 'hide_route_map';
const _hideStartEndAreaKey = 'hide_start_end_area';
const _hideHeartRateKey = 'hide_heart_rate';
const _hideCaloriesKey = 'hide_calories';
const _weeklyDistanceGoalKey = 'weekly_distance_goal_m';
const _monthlyDistanceGoalKey = 'monthly_distance_goal_m';
const _yearlyDistanceGoalKey = 'yearly_distance_goal_m';
const _countdownSecondsKey = 'run_countdown_seconds';
const _locationTrackingPresetKey = 'location_tracking_preset';
const _autoPauseEnabledKey = 'auto_pause_enabled';
const _showGhostMarkerKey = 'show_ghost_marker';
const _intervalWorkoutKey = 'run_interval_workout';
const _voiceCueEnabledKey = 'voice_cue_enabled';
const _kmVoiceCueEnabledKey = 'km_voice_cue_enabled';
const _ghostVoiceCueEnabledKey = 'ghost_voice_cue_enabled';
const _voiceCueVolumeKey = 'voice_cue_volume';
const _bodyWeightKgKey = 'body_weight_kg';
const _defaultShoeIdKey = 'default_shoe_id';

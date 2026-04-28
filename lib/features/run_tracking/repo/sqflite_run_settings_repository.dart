import 'package:runlini/core/persistence/runlini_database.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteRunSettingsRepository implements RunSettingsRepository {
  const SqfliteRunSettingsRepository({required RunliniDatabase database})
    : _database = database;

  final RunliniDatabase _database;

  @override
  Future<RunSettingsState> loadSettings() async {
    final db = await _database.database;
    final rows = await db.query('app_settings');
    final values = <String, String>{
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
    return RunSettingsState(
      display: RunDisplaySettings(
        distanceUnit: _enumByName(
          RunDistanceUnit.values,
          values[_distanceUnitKey],
          RunDistanceUnit.km,
        ),
        paceUnit: _enumByName(
          RunPaceUnit.values,
          values[_paceUnitKey],
          RunPaceUnit.minPerKm,
        ),
        speedUnit: _enumByName(
          RunSpeedUnit.values,
          values[_speedUnitKey],
          RunSpeedUnit.kmh,
        ),
      ),
      privacy: RunPrivacySettings(
        hideRouteMap: _bool(values[_hideRouteMapKey]),
        hideStartEndArea: _bool(values[_hideStartEndAreaKey]),
        hideHeartRate: _bool(values[_hideHeartRateKey]),
        hideCalories: _bool(values[_hideCaloriesKey]),
      ),
      distanceGoals: RunDistanceGoalSettings(
        weeklyGoalM: _distanceGoalM(
          values[_weeklyDistanceGoalKey],
          defaultWeeklyDistanceGoalM,
          runWeeklyDistanceGoalMinM,
          runWeeklyDistanceGoalMaxM,
        ),
        monthlyGoalM: _distanceGoalM(
          values[_monthlyDistanceGoalKey],
          defaultMonthlyDistanceGoalM,
          runMonthlyDistanceGoalMinM,
          runMonthlyDistanceGoalMaxM,
        ),
        yearlyGoalM: _distanceGoalM(
          values[_yearlyDistanceGoalKey],
          defaultYearlyDistanceGoalM,
          runYearlyDistanceGoalMinM,
          runYearlyDistanceGoalMaxM,
        ),
      ),
      countdownSeconds: _countdownSeconds(values[_countdownSecondsKey]),
      locationTrackingPreset: _enumByName(
        RunLocationTrackingPreset.values,
        values[_locationTrackingPresetKey],
        RunLocationTrackingPreset.balanced,
      ),
      showGhostMarker: _bool(values[_showGhostMarkerKey]),
      bodyWeightKg: _bodyWeightKg(values[_bodyWeightKgKey]),
      defaultShoeId: values[_defaultShoeIdKey],
    );
  }

  @override
  Future<void> saveSettings(RunSettingsState settings) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _saveValue(
        txn,
        _distanceUnitKey,
        settings.display.distanceUnit.name,
      );
      await _saveValue(txn, _paceUnitKey, settings.display.paceUnit.name);
      await _saveValue(txn, _speedUnitKey, settings.display.speedUnit.name);
      await _saveValue(
        txn,
        _hideRouteMapKey,
        '${settings.privacy.hideRouteMap}',
      );
      await _saveValue(
        txn,
        _hideStartEndAreaKey,
        '${settings.privacy.hideStartEndArea}',
      );
      await _saveValue(
        txn,
        _hideHeartRateKey,
        '${settings.privacy.hideHeartRate}',
      );
      await _saveValue(
        txn,
        _hideCaloriesKey,
        '${settings.privacy.hideCalories}',
      );
      await _saveValue(
        txn,
        _weeklyDistanceGoalKey,
        '${settings.distanceGoals.weeklyGoalM}',
      );
      await _saveValue(
        txn,
        _monthlyDistanceGoalKey,
        '${settings.distanceGoals.monthlyGoalM}',
      );
      await _saveValue(
        txn,
        _yearlyDistanceGoalKey,
        '${settings.distanceGoals.yearlyGoalM}',
      );
      await _saveValue(
        txn,
        _countdownSecondsKey,
        '${settings.countdownSeconds}',
      );
      await _saveValue(
        txn,
        _locationTrackingPresetKey,
        settings.locationTrackingPreset.name,
      );
      await _saveValue(txn, _showGhostMarkerKey, '${settings.showGhostMarker}');
      if (settings.bodyWeightKg == null) {
        await txn.delete(
          'app_settings',
          where: 'key = ?',
          whereArgs: <Object?>[_bodyWeightKgKey],
        );
      } else {
        await _saveValue(txn, _bodyWeightKgKey, '${settings.bodyWeightKg}');
      }
      if (settings.defaultShoeId == null) {
        await txn.delete(
          'app_settings',
          where: 'key = ?',
          whereArgs: <Object?>[_defaultShoeIdKey],
        );
      } else {
        await _saveValue(txn, _defaultShoeIdKey, settings.defaultShoeId!);
      }
    });
  }

  @override
  Future<List<RunShoe>> listShoes() async {
    final db = await _database.database;
    final rows = await db.query('run_shoes', orderBy: 'created_at DESC');
    return rows.map(_shoeFromRow).toList(growable: false);
  }

  @override
  Future<void> saveShoe(RunShoe shoe) async {
    final db = await _database.database;
    await db.insert(
      'run_shoes',
      _shoeRow(shoe),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> retireShoe(String id) async {
    final db = await _database.database;
    await db.update(
      'run_shoes',
      <String, Object?>{'retired': 1},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> deleteShoe(String id) async {
    final db = await _database.database;
    await db.update(
      'run_shoes',
      <String, Object?>{'retired': 1, 'deleted': 1},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> _saveValue(DatabaseExecutor db, String key, String value) async {
    await db.insert('app_settings', <String, Object?>{
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  RunShoe _shoeFromRow(Map<String, Object?> row) {
    return RunShoe(
      id: row['id']! as String,
      name: row['name']! as String,
      brand: row['brand']! as String,
      distanceLimitKm: (row['distance_limit_km']! as num).toDouble(),
      retired: (row['retired']! as num).toInt() == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      deleted: ((row['deleted'] as num?)?.toInt() ?? 0) == 1,
      imagePath: row['image_path'] as String?,
    );
  }

  Map<String, Object?> _shoeRow(RunShoe shoe) {
    return <String, Object?>{
      'id': shoe.id,
      'name': shoe.name,
      'brand': shoe.brand,
      'distance_limit_km': shoe.distanceLimitKm,
      'retired': shoe.retired ? 1 : 0,
      'deleted': shoe.deleted ? 1 : 0,
      'image_path': shoe.imagePath,
      'created_at': shoe.createdAt.toIso8601String(),
    };
  }

  bool _bool(String? value) => value == 'true';

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

  T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
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
const _showGhostMarkerKey = 'show_ghost_marker';
const _bodyWeightKgKey = 'body_weight_kg';
const _defaultShoeIdKey = 'default_shoe_id';

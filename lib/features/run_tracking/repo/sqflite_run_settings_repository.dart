import 'dart:convert';

import 'package:runlini/core/persistence/runlini_database.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:sqflite/sqflite.dart';

part 'sqflite_run_settings_repository_shoes.dart';
part 'sqflite_run_settings_repository_values.dart';

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
      autoPauseEnabled: _bool(values[_autoPauseEnabledKey]),
      showRecordRaceMarker: _bool(
        values[_showRecordRaceMarkerKey] ?? values[_legacyShowGhostMarkerKey],
      ),
      intervalWorkout: _intervalWorkout(values[_intervalWorkoutKey]),
      voiceCueEnabled: _boolWithDefault(values[_voiceCueEnabledKey], true),
      kmVoiceCueEnabled: _boolWithDefault(values[_kmVoiceCueEnabledKey], true),
      recordRaceVoiceCueEnabled: _boolWithDefault(
        values[_recordRaceVoiceCueEnabledKey] ??
            values[_legacyGhostVoiceCueEnabledKey],
        false,
      ),
      voiceCueVolume: _voiceCueVolume(values[_voiceCueVolumeKey]),
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
      await _saveValue(
        txn,
        _autoPauseEnabledKey,
        '${settings.autoPauseEnabled}',
      );
      await _saveValue(
        txn,
        _showRecordRaceMarkerKey,
        '${settings.showRecordRaceMarker}',
      );
      await _saveValue(
        txn,
        _intervalWorkoutKey,
        jsonEncode(settings.intervalWorkout.toJson()),
      );
      await _saveValue(txn, _voiceCueEnabledKey, '${settings.voiceCueEnabled}');
      await _saveValue(
        txn,
        _kmVoiceCueEnabledKey,
        '${settings.kmVoiceCueEnabled}',
      );
      await _saveValue(
        txn,
        _recordRaceVoiceCueEnabledKey,
        '${settings.recordRaceVoiceCueEnabled}',
      );
      await _saveValue(txn, _voiceCueVolumeKey, '${settings.voiceCueVolume}');
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
}

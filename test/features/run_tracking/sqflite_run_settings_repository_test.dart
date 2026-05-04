import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:runlini/core/persistence/runlini_database.dart';
import 'package:runlini/features/run_tracking/repo/sqflite_run_settings_repository.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('persists display, privacy, and default shoe settings', () async {
    final tempDir = await Directory.systemTemp.createTemp('runlini-settings');
    addTearDown(() => tempDir.delete(recursive: true));
    final dbPath = p.join(tempDir.path, 'runlini.db');
    final firstDb = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: dbPath,
    );
    final repository = SqfliteRunSettingsRepository(database: firstDb);
    await repository.saveSettings(
      const RunSettingsState(
        display: RunDisplaySettings(
          distanceUnit: RunDistanceUnit.mi,
          paceUnit: RunPaceUnit.minPerMi,
          speedUnit: RunSpeedUnit.mph,
        ),
        privacy: RunPrivacySettings(hideRouteMap: true, hideHeartRate: true),
        distanceGoals: RunDistanceGoalSettings(
          weeklyGoalM: 25000,
          monthlyGoalM: 120000,
          yearlyGoalM: 1400000,
        ),
        countdownSeconds: 7,
        locationTrackingPreset: RunLocationTrackingPreset.highAccuracy,
        showGhostMarker: true,
        voiceCueEnabled: false,
        kmVoiceCueEnabled: false,
        ghostVoiceCueEnabled: true,
        voiceCueVolume: 0.7,
        intervalWorkout: RunIntervalWorkout(
          enabled: true,
          work: RunIntervalTarget.distance(400),
          repeatCount: 6,
        ),
        bodyWeightKg: 70.5,
        defaultShoeId: 'shoe-a',
      ),
    );
    await firstDb.close();

    final secondDb = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: dbPath,
    );
    addTearDown(secondDb.close);
    final settings = await SqfliteRunSettingsRepository(
      database: secondDb,
    ).loadSettings();

    expect(settings.display.distanceUnit, RunDistanceUnit.mi);
    expect(settings.display.paceUnit, RunPaceUnit.minPerMi);
    expect(settings.display.speedUnit, RunSpeedUnit.mph);
    expect(settings.privacy.hideRouteMap, isTrue);
    expect(settings.privacy.hideHeartRate, isTrue);
    expect(settings.distanceGoals.weeklyGoalM, 25000);
    expect(settings.distanceGoals.monthlyGoalM, 120000);
    expect(settings.distanceGoals.yearlyGoalM, 1400000);
    expect(settings.countdownSeconds, 7);
    expect(
      settings.locationTrackingPreset,
      RunLocationTrackingPreset.highAccuracy,
    );
    expect(settings.showGhostMarker, isTrue);
    expect(settings.voiceCueEnabled, isFalse);
    expect(settings.kmVoiceCueEnabled, isFalse);
    expect(settings.ghostVoiceCueEnabled, isTrue);
    expect(settings.voiceCueVolume, 0.7);
    expect(settings.intervalWorkout.enabled, isTrue);
    expect(settings.intervalWorkout.work.distanceM, 400);
    expect(settings.intervalWorkout.repeatCount, 6);
    expect(settings.bodyWeightKg, 70.5);
    expect(settings.defaultShoeId, 'shoe-a');
  });

  test('falls back from invalid running settings', () async {
    final tempDir = await Directory.systemTemp.createTemp('runlini-settings');
    addTearDown(() => tempDir.delete(recursive: true));
    final database = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'runlini.db'),
    );
    addTearDown(database.close);
    final db = await database.database;
    await db.insert('app_settings', const <String, Object?>{
      'key': 'run_countdown_seconds',
      'value': '100',
    });
    await db.insert('app_settings', const <String, Object?>{
      'key': 'location_tracking_preset',
      'value': 'wild',
    });
    await db.insert('app_settings', const <String, Object?>{
      'key': 'body_weight_kg',
      'value': '500',
    });
    await db.insert('app_settings', const <String, Object?>{
      'key': 'weekly_distance_goal_m',
      'value': '0',
    });
    await db.insert('app_settings', const <String, Object?>{
      'key': 'monthly_distance_goal_m',
      'value': '2000000',
    });
    await db.insert('app_settings', const <String, Object?>{
      'key': 'yearly_distance_goal_m',
      'value': 'wild',
    });
    await db.insert('app_settings', const <String, Object?>{
      'key': 'voice_cue_volume',
      'value': '2',
    });

    final settings = await SqfliteRunSettingsRepository(
      database: database,
    ).loadSettings();

    expect(settings.countdownSeconds, runCountdownMaxSeconds);
    expect(settings.locationTrackingPreset, RunLocationTrackingPreset.balanced);
    expect(settings.bodyWeightKg, isNull);
    expect(settings.distanceGoals.weeklyGoalM, defaultWeeklyDistanceGoalM);
    expect(settings.distanceGoals.monthlyGoalM, defaultMonthlyDistanceGoalM);
    expect(settings.distanceGoals.yearlyGoalM, defaultYearlyDistanceGoalM);
    expect(settings.voiceCueEnabled, isTrue);
    expect(settings.kmVoiceCueEnabled, isTrue);
    expect(settings.ghostVoiceCueEnabled, isFalse);
    expect(settings.voiceCueVolume, defaultRunVoiceCueVolume);
  });

  test('adds, retires, and soft-deletes running shoes', () async {
    final tempDir = await Directory.systemTemp.createTemp('runlini-shoes');
    addTearDown(() => tempDir.delete(recursive: true));
    final database = RunliniDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'runlini.db'),
    );
    addTearDown(database.close);
    final repository = SqfliteRunSettingsRepository(database: database);
    final shoe = RunShoe(
      id: 'shoe-a',
      name: 'Pegasus',
      brand: 'Nike',
      distanceLimitKm: 800,
      retired: false,
      createdAt: DateTime.utc(2026, 4, 23),
      imagePath: '/tmp/pegasus.png',
    );

    await repository.saveShoe(shoe);
    final savedShoe = (await repository.listShoes()).single;
    expect(savedShoe.retired, isFalse);
    expect(savedShoe.imagePath, '/tmp/pegasus.png');

    await repository.retireShoe(shoe.id);

    final shoes = await repository.listShoes();
    expect(shoes, hasLength(1));
    expect(shoes.single.retired, isTrue);
    expect(shoes.single.deleted, isFalse);

    await repository.deleteShoe(shoe.id);

    final deletedShoes = await repository.listShoes();
    expect(deletedShoes, hasLength(1));
    expect(deletedShoes.single.retired, isTrue);
    expect(deletedShoes.single.deleted, isTrue);
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/repo/sqflite_run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_history_period.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

final runSettingsRepositoryProvider = Provider<RunSettingsRepository>((
  Ref ref,
) {
  return SqfliteRunSettingsRepository(
    database: ref.watch(runliniDatabaseProvider),
  );
});

class RunSettingsController extends AsyncNotifier<RunSettingsState> {
  @override
  FutureOr<RunSettingsState> build() {
    return ref.watch(runSettingsRepositoryProvider).loadSettings();
  }

  Future<void> setDistanceUnit(RunDistanceUnit unit) async {
    final current = state.value ?? const RunSettingsState();
    final next = current.copyWith(
      display: RunDisplaySettings(
        distanceUnit: unit,
        paceUnit: unit == RunDistanceUnit.mi
            ? RunPaceUnit.minPerMi
            : RunPaceUnit.minPerKm,
        speedUnit: unit == RunDistanceUnit.mi
            ? RunSpeedUnit.mph
            : RunSpeedUnit.kmh,
      ),
    );
    await _save(next);
  }

  Future<void> setPrivacy(RunPrivacySettings privacy) async {
    final current = state.value ?? const RunSettingsState();
    await _save(current.copyWith(privacy: privacy));
  }

  Future<void> setDistanceGoals(RunDistanceGoalSettings distanceGoals) async {
    final current = state.value ?? const RunSettingsState();
    await _save(current.copyWith(distanceGoals: distanceGoals));
  }

  Future<void> setDistanceGoal(
    RunHistoryPeriod period,
    double distanceM,
  ) async {
    final current = state.value ?? const RunSettingsState();
    await _save(
      current.copyWith(
        distanceGoals: current.distanceGoals.copyWithGoal(period, distanceM),
      ),
    );
  }

  Future<void> setCountdownSeconds(int seconds) async {
    final current = state.value ?? const RunSettingsState();
    final clamped = seconds.clamp(
      runCountdownMinSeconds,
      runCountdownMaxSeconds,
    );
    await _save(current.copyWith(countdownSeconds: clamped));
  }

  Future<void> setLocationTrackingPreset(
    RunLocationTrackingPreset preset,
  ) async {
    final current = state.value ?? const RunSettingsState();
    await _save(current.copyWith(locationTrackingPreset: preset));
  }

  Future<void> setShowGhostMarker(bool visible) async {
    final current = state.value ?? const RunSettingsState();
    await _save(current.copyWith(showGhostMarker: visible));
  }

  Future<void> setBodyWeightKg(double? weightKg) async {
    final current = state.value ?? const RunSettingsState();
    final validWeight =
        weightKg == null ||
            weightKg < runBodyWeightMinKg ||
            weightKg > runBodyWeightMaxKg
        ? null
        : weightKg;
    await _save(
      current.copyWith(
        bodyWeightKg: validWeight,
        clearBodyWeightKg: validWeight == null,
      ),
    );
  }

  Future<void> setDefaultShoeId(String? id) async {
    final current = state.value ?? const RunSettingsState();
    await _save(
      current.copyWith(defaultShoeId: id, clearDefaultShoeId: id == null),
    );
  }

  Future<RunShoe> addShoe({
    required String name,
    required String brand,
    required double distanceLimitKm,
    String? imagePath,
  }) async {
    final repository = ref.read(runSettingsRepositoryProvider);
    final createdAt = DateTime.now().toUtc();
    final shoe = RunShoe(
      id: 'shoe_${createdAt.microsecondsSinceEpoch}',
      name: name.trim(),
      brand: brand.trim(),
      distanceLimitKm: distanceLimitKm,
      retired: false,
      createdAt: createdAt,
      imagePath: imagePath,
    );
    await repository.saveShoe(shoe);
    final current = state.value ?? const RunSettingsState();
    if (current.defaultShoeId == null) {
      await _save(current.copyWith(defaultShoeId: shoe.id));
    } else {
      ref.invalidate(runShoeListProvider);
    }
    return shoe;
  }

  Future<void> updateShoe(RunShoe shoe) async {
    await ref.read(runSettingsRepositoryProvider).saveShoe(shoe);
    ref.invalidate(runShoeListProvider);
    ref.invalidate(defaultRunShoeProvider);
  }

  Future<void> retireShoe(String id) async {
    await ref.read(runSettingsRepositoryProvider).retireShoe(id);
    final current = state.value ?? const RunSettingsState();
    if (current.defaultShoeId == id) {
      await _save(current.copyWith(clearDefaultShoeId: true));
    } else {
      ref.invalidate(runShoeListProvider);
    }
  }

  Future<void> deleteShoe(String id) async {
    await ref.read(runSettingsRepositoryProvider).deleteShoe(id);
    final current = state.value ?? const RunSettingsState();
    if (current.defaultShoeId == id) {
      await _save(current.copyWith(clearDefaultShoeId: true));
    } else {
      ref.invalidate(runShoeListProvider);
    }
  }

  Future<void> _save(RunSettingsState next) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await ref.read(runSettingsRepositoryProvider).saveSettings(next);
      return next;
    });
    state = result;
    ref.invalidate(runShoeListProvider);
    ref.invalidate(defaultRunShoeProvider);
  }
}

final runSettingsControllerProvider =
    AsyncNotifierProvider<RunSettingsController, RunSettingsState>(
      RunSettingsController.new,
    );

final runDisplaySettingsProvider = Provider<RunDisplaySettings>((Ref ref) {
  return ref.watch(runSettingsControllerProvider).value?.display ??
      const RunDisplaySettings();
});

final runPrivacySettingsProvider = Provider<RunPrivacySettings>((Ref ref) {
  return ref.watch(runSettingsControllerProvider).value?.privacy ??
      const RunPrivacySettings();
});

final runDistanceGoalSettingsProvider = Provider<RunDistanceGoalSettings>((
  Ref ref,
) {
  return ref.watch(runSettingsControllerProvider).value?.distanceGoals ??
      const RunDistanceGoalSettings();
});

final runBodyWeightKgProvider = Provider<double?>((Ref ref) {
  return ref.watch(runSettingsControllerProvider).value?.bodyWeightKg;
});

final runShoeListProvider = FutureProvider<List<RunShoe>>((Ref ref) async {
  return ref.watch(runSettingsRepositoryProvider).listShoes();
});

final defaultRunShoeProvider = FutureProvider<RunShoe?>((Ref ref) async {
  final settings = await ref.watch(runSettingsControllerProvider.future);
  final defaultId = settings.defaultShoeId;
  if (defaultId == null) {
    return null;
  }
  final shoes = await ref.watch(runShoeListProvider.future);
  for (final shoe in shoes) {
    if (shoe.id == defaultId && !shoe.retired && !shoe.deleted) {
      return shoe;
    }
  }
  return null;
});

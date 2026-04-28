import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

final runLocationTrackingPresetProvider = Provider<RunLocationTrackingPreset>((
  Ref ref,
) {
  return ref
          .watch(runSettingsControllerProvider)
          .value
          ?.locationTrackingPreset ??
      RunLocationTrackingPreset.balanced;
});

final locationTrackingConfigProvider =
    Provider.family<LocationTrackingConfig, LocationTrackingMode>((
      Ref ref,
      LocationTrackingMode mode,
    ) {
      final preset = ref.watch(runLocationTrackingPresetProvider);
      return locationTrackingConfigForPreset(preset, mode);
    });

LocationTrackingConfig locationTrackingConfigForPreset(
  RunLocationTrackingPreset preset,
  LocationTrackingMode mode,
) {
  return switch ((preset, mode)) {
    (RunLocationTrackingPreset.batterySaver, LocationTrackingMode.passive) =>
      const LocationTrackingConfig(
        androidInterval: Duration(seconds: 5),
        distanceFilterM: 10,
      ),
    (RunLocationTrackingPreset.batterySaver, LocationTrackingMode.workout) =>
      const LocationTrackingConfig(
        androidInterval: Duration(seconds: 2),
        distanceFilterM: 5,
      ),
    (RunLocationTrackingPreset.balanced, LocationTrackingMode.passive) =>
      LocationTrackingConfig.passiveDefault,
    (RunLocationTrackingPreset.balanced, LocationTrackingMode.workout) =>
      LocationTrackingConfig.workoutDefault,
    (RunLocationTrackingPreset.highAccuracy, LocationTrackingMode.passive) =>
      const LocationTrackingConfig(
        androidInterval: Duration(seconds: 2),
        distanceFilterM: 3,
      ),
    (RunLocationTrackingPreset.highAccuracy, LocationTrackingMode.workout) =>
      const LocationTrackingConfig(
        androidInterval: Duration(seconds: 1),
        distanceFilterM: 1,
      ),
  };
}

import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/live_run_metrics_formatters.dart';

const _metersPerMile = 1609.344;
const _milesPerKilometer = 0.6213711922;

String formatRunDistance(
  double distanceM,
  RunDisplaySettings settings, {
  int decimals = 1,
}) {
  final value = settings.distanceUnit == RunDistanceUnit.mi
      ? distanceM / _metersPerMile
      : distanceM / 1000;
  return '${value.toStringAsFixed(decimals)} ${distanceUnitLabel(settings)}';
}

String formatRunDistanceGap(double distanceM, RunDisplaySettings settings) {
  final absDistanceM = distanceM.abs();
  if (settings.distanceUnit == RunDistanceUnit.mi) {
    return '${(absDistanceM / _metersPerMile).toStringAsFixed(2)} mi';
  }
  if (absDistanceM < 1000) {
    return '${absDistanceM.round()} m';
  }
  return '${(absDistanceM / 1000).toStringAsFixed(2)} km';
}

double splitDistanceMetersForDisplay(RunDisplaySettings settings) {
  return settings.distanceUnit == RunDistanceUnit.mi ? _metersPerMile : 1000;
}

String distanceUnitLabel(RunDisplaySettings settings) {
  return settings.distanceUnit == RunDistanceUnit.mi ? 'mi' : 'km';
}

String paceUnitLabel(RunDisplaySettings settings) {
  return settings.paceUnit == RunPaceUnit.minPerMi ? 'min/mi' : 'min/km';
}

String speedUnitLabel(RunDisplaySettings settings) {
  return settings.speedUnit == RunSpeedUnit.mph ? 'mph' : 'km/h';
}

double paceForDisplay(double secondsPerKm, RunDisplaySettings settings) {
  return settings.paceUnit == RunPaceUnit.minPerMi
      ? secondsPerKm * (_metersPerMile / 1000)
      : secondsPerKm;
}

double distanceForDisplay(double distanceM, RunDisplaySettings settings) {
  return settings.distanceUnit == RunDistanceUnit.mi
      ? distanceM / _metersPerMile
      : distanceM / 1000;
}

double distanceMetersFromDisplay(double distance, RunDisplaySettings settings) {
  return settings.distanceUnit == RunDistanceUnit.mi
      ? distance * _metersPerMile
      : distance * 1000;
}

double speedForDisplay(double speedKmh, RunDisplaySettings settings) {
  return settings.speedUnit == RunSpeedUnit.mph
      ? speedKmh * _milesPerKilometer
      : speedKmh;
}

String formatRunPace(double? secondsPerKm, RunDisplaySettings settings) {
  if (secondsPerKm == null || !secondsPerKm.isFinite || secondsPerKm <= 0) {
    return '--:-- /${distanceUnitLabel(settings)}';
  }
  final displayPace = paceForDisplay(secondsPerKm, settings);
  final rounded = displayPace.round();
  final minutes = rounded ~/ 60;
  final seconds = rounded % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')} '
      '/${distanceUnitLabel(settings)}';
}

String formatRunPaceCompact(double? secondsPerKm, RunDisplaySettings settings) {
  return formatRunPace(
    secondsPerKm,
    settings,
  ).replaceFirst(' /${distanceUnitLabel(settings)}', '');
}

String formatRunSpeed(double speedKmh, RunDisplaySettings settings) {
  return '${speedForDisplay(speedKmh, settings).toStringAsFixed(1)} '
      '${speedUnitLabel(settings)}';
}

String formatRunElapsed(int durationMs) => formatLiveRunElapsed(durationMs);

String formatLiveRunDistance(double distanceKm) {
  return '${distanceKm.toStringAsFixed(2)} km';
}

String formatLiveRunElapsed(int elapsedMs) {
  final totalSeconds = elapsedMs ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  return '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
}

String formatLiveRunAveragePace(double? secondsPerKm) {
  if (secondsPerKm == null || !secondsPerKm.isFinite || secondsPerKm <= 0) {
    return '--:-- /km';
  }

  final rounded = secondsPerKm.round();
  final minutes = rounded ~/ 60;
  final seconds = rounded % 60;
  return '$minutes:${_twoDigits(seconds)} /km';
}

String formatLiveRunAverageSpeed(double speedKmh) {
  if (!speedKmh.isFinite || speedKmh <= 0) {
    return '0.0 km/h';
  }

  return '${speedKmh.toStringAsFixed(1)} km/h';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

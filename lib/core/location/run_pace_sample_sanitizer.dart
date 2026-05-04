class RunPaceSampleSanitizer {
  const RunPaceSampleSanitizer({
    this.minSpeedMps = 0.7,
    this.minPaceSecPerKm = 120,
    this.maxPaceSecPerKm = 1800,
  });

  final double minSpeedMps;
  final double minPaceSecPerKm;
  final double maxPaceSecPerKm;

  double? acceptedSpeedMps(double? speedMps) {
    if (speedMps == null || !speedMps.isFinite || speedMps <= minSpeedMps) {
      return null;
    }
    return speedMps;
  }

  double? paceFromSpeedMps(double? speedMps) {
    final acceptedSpeed = acceptedSpeedMps(speedMps);
    if (acceptedSpeed == null) {
      return null;
    }
    final pace = 1000 / acceptedSpeed;
    return isRenderablePace(pace) ? pace : null;
  }

  bool isRenderablePace(double? paceSecPerKm) {
    return paceSecPerKm != null &&
        paceSecPerKm.isFinite &&
        paceSecPerKm >= minPaceSecPerKm &&
        paceSecPerKm <= maxPaceSecPerKm;
  }
}

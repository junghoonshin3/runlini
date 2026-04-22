String formatRunDetailPaceCompact(double secondsPerKm) {
  if (!secondsPerKm.isFinite || secondsPerKm <= 0) {
    return '--:--/KM';
  }

  final rounded = secondsPerKm.round();
  final minutes = rounded ~/ 60;
  final seconds = rounded % 60;
  return "$minutes'${seconds.toString().padLeft(2, '0')}\"/KM";
}

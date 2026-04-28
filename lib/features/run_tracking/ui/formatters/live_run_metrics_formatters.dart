String formatLiveRunElapsed(int elapsedMs) {
  final totalSeconds = elapsedMs ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  return '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
}

String formatLiveRunCalories(double? caloriesKcal) {
  if (caloriesKcal == null || caloriesKcal <= 0 || !caloriesKcal.isFinite) {
    return '-- kcal';
  }
  return '${caloriesKcal.round()} kcal';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

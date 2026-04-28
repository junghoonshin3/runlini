import 'package:runlini/features/run_tracking/types/run_settings.dart';

class RunCalorieCalculator {
  const RunCalorieCalculator();

  static const double _activeKcalPerKgPerKm = 1;

  double? activeCaloriesKcal({
    required double distanceM,
    required double? bodyWeightKg,
  }) {
    if (bodyWeightKg == null ||
        bodyWeightKg < runBodyWeightMinKg ||
        bodyWeightKg > runBodyWeightMaxKg ||
        distanceM <= 0 ||
        !distanceM.isFinite) {
      return null;
    }

    return bodyWeightKg * (distanceM / 1000) * _activeKcalPerKgPerKm;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_calorie_calculator.dart';

void main() {
  const calculator = RunCalorieCalculator();

  test('calculates active running calories from body weight and distance', () {
    expect(
      calculator.activeCaloriesKcal(distanceM: 5000, bodyWeightKg: 70),
      350,
    );
  });

  test('returns null without a valid body weight or distance', () {
    expect(
      calculator.activeCaloriesKcal(distanceM: 5000, bodyWeightKg: null),
      isNull,
    );
    expect(
      calculator.activeCaloriesKcal(distanceM: 0, bodyWeightKg: 70),
      isNull,
    );
    expect(
      calculator.activeCaloriesKcal(distanceM: 5000, bodyWeightKg: 10),
      isNull,
    );
    expect(
      calculator.activeCaloriesKcal(distanceM: 5000, bodyWeightKg: 300),
      isNull,
    );
  });
}

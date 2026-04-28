import 'dart:math' as math;

class ChartBounds {
  const ChartBounds({required this.min, required this.max});

  factory ChartBounds.from({required double min, required double max}) {
    final spread = max - min;
    if (spread <= 0) {
      final padding = math.max(1, min.abs() * 0.08);
      return ChartBounds(min: min - padding, max: max + padding);
    }

    final padding = math.max(1, spread * 0.14);
    return ChartBounds(min: min - padding, max: max + padding);
  }

  final double min;
  final double max;
}

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class PaceColorMapper {
  const PaceColorMapper({
    this.fastRatio = 0.85,
    this.slowRatio = 1.15,
    this.colorSteps = 32,
  });

  final double fastRatio;
  final double slowRatio;
  final int colorSteps;

  Color colorFor(double? paceSecPerKm) {
    if (paceSecPerKm == null) {
      return AppColors.chalk;
    }

    if (paceSecPerKm < 240) {
      return AppColors.voltGreen;
    }

    if (paceSecPerKm < 300) {
      return AppColors.cyan;
    }

    if (paceSecPerKm < 360) {
      return AppColors.amber;
    }

    return AppColors.electricRed;
  }

  Color colorForAverageRelative({
    required double? paceSecPerKm,
    required double averagePaceSecPerKm,
  }) {
    if (paceSecPerKm == null || averagePaceSecPerKm <= 0) {
      return AppColors.chalk;
    }

    final paceRatio = paceSecPerKm / averagePaceSecPerKm;
    if (paceRatio <= 0.95) {
      return AppColors.voltGreen;
    }

    if (paceRatio <= 1.06) {
      return AppColors.amber;
    }

    if (paceRatio <= 1.14) {
      return AppColors.orange;
    }

    return AppColors.electricRed;
  }

  Color colorForRelativeGradient({
    required double? paceSecPerKm,
    required double baselinePaceSecPerKm,
  }) {
    if (paceSecPerKm == null || baselinePaceSecPerKm <= 0) {
      return AppColors.chalk;
    }

    final ratio = paceSecPerKm / baselinePaceSecPerKm;
    return colorForRatioGradient(ratio);
  }

  Color colorForRatioGradient(double paceRatio) {
    if (!paceRatio.isFinite) {
      return AppColors.chalk;
    }
    if ((paceRatio - 1).abs() < 0.000001) {
      return AppColors.amber;
    }

    final normalized = _quantizedNormalizedRatio(paceRatio);
    if (normalized <= 0.5) {
      return Color.lerp(AppColors.voltGreen, AppColors.amber, normalized * 2) ??
          AppColors.amber;
    }

    return Color.lerp(
          AppColors.amber,
          AppColors.electricRed,
          (normalized - 0.5) * 2,
        ) ??
        AppColors.electricRed;
  }

  double _quantizedNormalizedRatio(double paceRatio) {
    final range = slowRatio - fastRatio;
    if (range <= 0) {
      return 0.5;
    }

    final normalized = ((paceRatio - fastRatio) / range).clamp(0.0, 1.0);
    if (colorSteps <= 1) {
      return normalized.toDouble();
    }

    final stepCount = colorSteps - 1;
    return (normalized * stepCount).round() / stepCount;
  }
}

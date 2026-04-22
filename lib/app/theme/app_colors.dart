import 'package:flutter/material.dart';
import 'package:runlini/features/ghost_racer/types/ghost_frame.dart';

abstract final class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color voltGreen = Color(0xFFCEFF00);
  static const Color electricRed = Color(0xFFFF3B30);
  static const Color chalk = Color(0xFFF5F7FA);
  static const Color graphite = Color(0xFF181818);
  static const Color panel = Color(0xFF0B0B0B);
  static const Color cyan = Color(0xFF4AE2FF);
  static const Color amber = Color(0xFFFFC145);
  static const Color orange = Color(0xFFFF8A00);
  static const Color muted = Color(0xFF8B8F98);

  static Color borderFor(GhostRelativeState state) {
    switch (state) {
      case GhostRelativeState.ahead:
        return voltGreen;
      case GhostRelativeState.behind:
        return electricRed;
      case GhostRelativeState.level:
        return chalk;
    }
  }
}

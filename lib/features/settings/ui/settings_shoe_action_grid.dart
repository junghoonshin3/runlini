import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class ShoeMileageProgress extends StatelessWidget {
  const ShoeMileageProgress({
    super.key,
    required this.distanceKm,
    required this.limitKm,
  });

  final double distanceKm;
  final double limitKm;

  @override
  Widget build(BuildContext context) {
    final progress = limitKm <= 0
        ? 0.0
        : (distanceKm / limitKm).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: AppColors.chalk.withValues(alpha: 0.12),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.voltGreen),
      ),
    );
  }
}

class ShoeActionGrid extends StatelessWidget {
  const ShoeActionGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

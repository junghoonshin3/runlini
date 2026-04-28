import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunPanel extends StatelessWidget {
  const RunPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AppColors.panel,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor ?? AppColors.chalk.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class RunSectionPanel extends StatelessWidget {
  const RunSectionPanel({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RunPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunCompactButton extends StatelessWidget {
  const RunCompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final accent = danger ? AppColors.electricRed : AppColors.voltGreen;
    final borderColor = selected ? accent : AppColors.chalk;
    final textColor = selected ? AppColors.black : AppColors.chalk;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

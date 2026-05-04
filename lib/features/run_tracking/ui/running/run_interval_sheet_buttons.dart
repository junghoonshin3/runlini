import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunIntervalDoneButton extends StatelessWidget {
  const RunIntervalDoneButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        key: const Key('run-interval-done-button'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.black,
          backgroundColor: AppColors.voltGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text(
          '완료',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class RunIntervalStepperButton extends StatelessWidget {
  const RunIntervalStepperButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton.filled(
        onPressed: onPressed,
        color: AppColors.black,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.voltGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

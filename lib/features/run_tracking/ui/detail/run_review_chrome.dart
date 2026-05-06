import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunReviewChrome extends StatelessWidget {
  const RunReviewChrome({super.key, this.onClose, this.onMore});

  final VoidCallback? onClose;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    if (onClose == null && onMore == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ChromeButton(
          icon: Icons.close_rounded,
          onTap: onClose,
          actionKey: const Key('run-detail-close-button'),
        ),
        _ChromeButton(
          icon: Icons.delete_outline_rounded,
          onTap: onMore,
          actionKey: const Key('run-detail-more-button'),
        ),
      ],
    );
  }
}

class _ChromeButton extends StatelessWidget {
  const _ChromeButton({
    required this.icon,
    this.onTap,
    required this.actionKey,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Key actionKey;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: onTap == null ? null : actionKey,
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.chalk.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.chalk, size: 26),
      ),
    );
  }
}

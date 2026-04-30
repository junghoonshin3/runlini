import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

class SettingsFailedBackupRetry extends StatelessWidget {
  const SettingsFailedBackupRetry({
    super.key,
    required this.destinationLabel,
    required this.failedCount,
    required this.isBusy,
    required this.onRetry,
  });

  final String destinationLabel;
  final int failedCount;
  final bool isBusy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$destinationLabel 전송 실패 $failedCount개',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        SettingsCompactButton(
          key: const Key('settings-health-retry-failed-button'),
          label: '다시 보내기',
          danger: true,
          onPressed: isBusy ? null : onRetry,
        ),
      ],
    );
  }
}

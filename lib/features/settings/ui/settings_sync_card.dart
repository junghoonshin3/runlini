import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/settings/ui/settings_section_panel.dart';

class SettingsSyncCard extends StatelessWidget {
  const SettingsSyncCard({
    super.key,
    required this.title,
    required this.status,
    this.statusLoading = false,
    this.actionKey,
    this.actionLabel,
    this.onPressed,
    this.child,
  });

  final String title;
  final String status;
  final bool statusLoading;
  final Key? actionKey;
  final String? actionLabel;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.24),
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsStatusRow(
            label: title,
            value: status,
            valueWidget: statusLoading
                ? const SettingsStatusSkeletonValue()
                : null,
          ),
          const SizedBox(height: 8),
          child ??
              SettingsCompactButton(
                key: actionKey,
                label: actionLabel ?? '',
                onPressed: onPressed,
              ),
        ],
      ),
    );
  }
}

class SettingsSyncErrorText extends StatelessWidget {
  const SettingsSyncErrorText({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(label, style: _errorStyle),
    );
  }
}

const _errorStyle = TextStyle(
  color: AppColors.electricRed,
  fontWeight: FontWeight.w900,
);

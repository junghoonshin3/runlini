import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class SettingsSectionPanel extends StatelessWidget {
  const SettingsSectionPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class SettingsCompactButton extends StatelessWidget {
  const SettingsCompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.danger = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool danger;
  final bool expand;

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
            width: expand ? double.infinity : null,
            child: Text(
              label,
              textAlign: TextAlign.center,
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

class SettingsStatusRow extends StatelessWidget {
  const SettingsStatusRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: _labelStyle)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: _valueStyle),
          ),
        ],
      ),
    );
  }
}

const _labelStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);

const _valueStyle = TextStyle(
  color: AppColors.chalk,
  fontWeight: FontWeight.w900,
);

// 기록 레이스 상단 카드의 공통 레이아웃을 제공한다
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunRecordRaceCardShell extends StatelessWidget {
  const RunRecordRaceCardShell({
    super.key,
    required this.accent,
    required this.title,
    required this.message,
    this.detail,
    this.primaryLabel,
    this.primaryKey,
    this.onPrimary,
    this.secondaryLabel,
    this.secondaryKey,
    this.onSecondary,
    this.enabled = true,
  });

  final Color accent;
  final String title;
  final String message;
  final String? detail;
  final String? primaryLabel;
  final Key? primaryKey;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final Key? secondaryKey;
  final VoidCallback? onSecondary;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = enabled ? AppColors.chalk : AppColors.muted;
    final hasPrimary = primaryLabel != null && onPrimary != null;
    final hasSecondary = secondaryLabel != null && onSecondary != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.9),
              border: Border.all(color: accent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          if (detail != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              detail!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (enabled) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.route_rounded,
                        color: AppColors.voltGreen,
                        size: 22,
                      ),
                    ],
                  ],
                ),
                if (enabled && (hasPrimary || hasSecondary)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (hasSecondary)
                        Expanded(
                          child: OutlinedButton(
                            key: secondaryKey,
                            onPressed: onSecondary,
                            style: _outlinedButtonStyle(),
                            child: FittedBox(child: Text(secondaryLabel!)),
                          ),
                        ),
                      if (hasPrimary && hasSecondary) const SizedBox(width: 8),
                      if (hasPrimary)
                        Expanded(
                          child: FilledButton(
                            key: primaryKey,
                            onPressed: onPrimary,
                            style: _filledButtonStyle(),
                            child: FittedBox(child: Text(primaryLabel!)),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.chalk,
      side: const BorderSide(color: AppColors.chalk, width: 2),
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _filledButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AppColors.voltGreen,
      foregroundColor: AppColors.black,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

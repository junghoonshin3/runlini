import 'dart:async';

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunRecordRaceCompletionOverlay extends StatelessWidget {
  const RunRecordRaceCompletionOverlay({
    required this.onContinue,
    required this.onStop,
    super.key,
  });

  final VoidCallback onContinue;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('record-race-run-completion-dialog'),
      color: AppColors.black.withValues(alpha: 0.74),
      child: Center(
        child: Container(
          width: 304,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.voltGreen, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '기록 레이스 코스 완료',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.voltGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '이 코스를 마쳤어요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.chalk,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key(
                        'continue-after-record-race-completion-button',
                      ),
                      onPressed: onContinue,
                      child: const Text('계속 기록'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const Key(
                        'stop-after-record-race-completion-button',
                      ),
                      onPressed: () => unawaited(onStop()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.electricRed,
                        foregroundColor: AppColors.chalk,
                      ),
                      child: const Text('종료하고 리뷰'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

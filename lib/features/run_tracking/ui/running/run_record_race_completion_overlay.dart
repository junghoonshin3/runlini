import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_motion.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';

class RunRecordRaceCompletionOverlay extends StatelessWidget {
  const RunRecordRaceCompletionOverlay({
    required this.summary,
    required this.onContinue,
    required this.onStop,
    super.key,
  });

  final RunSessionRecordRaceSummary summary;
  final VoidCallback onContinue;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('record-race-run-completion-dialog'),
      color: AppColors.black.withValues(alpha: 0.74),
      child: Center(
        child: RunliniOverlayEntrance(
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
                  '기록 레이스 완료',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.voltGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '실시간 결과',
                  key: Key('record-race-completion-result-label'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatResult(summary),
                  key: const Key('record-race-completion-result-value'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.chalk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '러닝 기록은 계속 중입니다.',
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
                        child: const Text('계속 달리기'),
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
                        child: const Text('러닝 종료'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatResult(RunSessionRecordRaceSummary summary) {
    if (summary.result == RunSessionRecordRaceResult.offRoute) {
      return '경로를 벗어났어요';
    }
    if (summary.result == RunSessionRecordRaceResult.level ||
        summary.timeGapMs.abs() <= 3000) {
      return '기록 레이스와 거의 같아요';
    }

    final gap = _formatKoreanDuration(summary.timeGapMs.abs());
    return summary.timeGapMs > 0 ? '기록 레이스보다 $gap 빨랐어요' : '기록 레이스보다 $gap 늦었어요';
  }

  String _formatKoreanDuration(int milliseconds) {
    final totalSeconds = math.max(1, milliseconds ~/ 1000);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes <= 0) {
      return '$seconds초';
    }
    if (seconds == 0) {
      return '$minutes분';
    }
    return '$minutes분 $seconds초';
  }
}

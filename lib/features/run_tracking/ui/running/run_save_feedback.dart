import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_workout_recorder.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';

Future<void> saveFinishedRunWithFeedback(
  BuildContext context,
  WidgetRef ref,
) async {
  final result = await ref
      .read(runPlaybackControllerProvider.notifier)
      .saveFinishedRun();
  if (!context.mounted || result == null) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(saveFinishedRunMessage(result))));
}

String saveFinishedRunMessage(HealthWorkoutExportResult result) {
  return switch (result.kind) {
    HealthWorkoutExportResultKind.synced => '저장됨 · Health에도 백업됨',
    HealthWorkoutExportResultKind.skipped => '저장됨 · 앱에만 저장됨',
    HealthWorkoutExportResultKind.failed => '저장됨 · Health 백업 실패',
  };
}

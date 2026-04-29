import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_destination_labels.dart';
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

String saveFinishedRunMessage(
  HealthWorkoutExportResult result, {
  TargetPlatform? targetPlatform,
}) {
  final platform = targetPlatform ?? defaultTargetPlatform;
  return switch (result.kind) {
    HealthWorkoutExportResultKind.synced =>
      '저장됨 · ${healthDestinationSavedLabel(platform)}',
    HealthWorkoutExportResultKind.skipped => '저장됨 · 앱에만 저장됨',
    HealthWorkoutExportResultKind.failed =>
      '저장됨 · ${healthDestinationFailedLabel(platform)}',
  };
}

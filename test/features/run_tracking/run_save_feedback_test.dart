import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_workout_export_result.dart';
import 'package:runlini/features/run_tracking/ui/running/run_save_feedback.dart';

void main() {
  test('formats save feedback with platform Health destination', () {
    expect(
      saveFinishedRunMessage(
        const HealthWorkoutExportResult.synced(),
        targetPlatform: TargetPlatform.android,
      ),
      '저장됨 · Health Connect에 저장됨',
    );
    expect(
      saveFinishedRunMessage(
        const HealthWorkoutExportResult.failed(),
        targetPlatform: TargetPlatform.iOS,
      ),
      '저장됨 · 건강 앱 전송 실패',
    );
  });
}

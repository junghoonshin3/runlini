// 기록 레이스 선택 시트 실행과 선택 확정을 조율한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/record_race/ui/record_race_session_picker_sheet.dart';
import 'package:runlini/features/run_tracking/service/run_record_race_recommendation_service.dart';
import 'package:runlini/features/run_tracking/state/run_interval_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/running/run_training_mode_conflict_dialog.dart';

Future<void> openRecordRacePicker({
  required BuildContext context,
  required WidgetRef ref,
  List<RunSessionSummary>? summaries,
  RunRecordRaceRecommendation? recommendation,
}) async {
  final List<RunSessionSummary> availableSummaries;
  if (summaries == null) {
    availableSummaries = await ref.read(runSessionSummaryListProvider.future);
  } else {
    availableSummaries = summaries;
  }
  if (!context.mounted) {
    return;
  }

  final selectedSummary = await showModalBottomSheet<RunSessionSummary>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 140),
      reverseDuration: Duration(milliseconds: 80),
    ),
    builder: (BuildContext context) {
      return RecordRaceSessionPickerSheet(
        summaries: availableSummaries,
        recommendedSummary: recommendation?.summary,
        recommendationReason: recommendation == null
            ? null
            : recordRaceRecommendationReasonLabel(recommendation.reason),
      );
    },
  );
  if (!context.mounted || selectedSummary == null) {
    return;
  }

  await selectRecordRaceSummary(
    context: context,
    ref: ref,
    summary: selectedSummary,
  );
}

Future<void> selectRecordRaceSummary({
  required BuildContext context,
  required WidgetRef ref,
  required RunSessionSummary summary,
}) async {
  final runSettings =
      ref.read(runSettingsControllerProvider).value ?? const RunSettingsState();
  final intervalWorkout = runSettings.intervalWorkout;
  if (isRunIntervalEnabledForRuntime(intervalWorkout)) {
    final confirmed = await confirmDisableIntervalForRecordRace(context);
    if (!context.mounted || !confirmed) {
      return;
    }
    await ref
        .read(runSettingsControllerProvider.notifier)
        .setIntervalWorkout(intervalWorkout.copyWith(enabled: false));
  }

  ref.read(recordRaceSettingsProvider.notifier).selectSession(summary);
}

String recordRaceRecommendationReasonLabel(
  RunRecordRaceRecommendationReason reason,
) {
  return switch (reason) {
    RunRecordRaceRecommendationReason.sameWeekday => '같은 요일 기록으로 달리기',
    RunRecordRaceRecommendationReason.latest => '최근 기록으로 달리기',
  };
}

// 러닝 시작 전 기록 레이스 추천과 선택 진입 카드를 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/record_race/types/record_race_settings_state.dart';
import 'package:runlini/features/run_tracking/service/run_record_race_recommendation_service.dart';
import 'package:runlini/features/run_tracking/state/run_record_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_card_shell.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_picker_flow.dart';

class RunRecordRaceRecommendationCard extends ConsumerWidget {
  const RunRecordRaceRecommendationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(recordRaceSettingsProvider);
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    final summariesAsync = ref.watch(runSessionSummaryListProvider);
    final loadedSummaries = summariesAsync.maybeWhen(
      data: (summaries) => summaries,
      orElse: () => const <RunSessionSummary>[],
    );
    final selectedSummary =
        _selectedSummary(settings, loadedSummaries) ??
        settings.selectedSessionSummary;

    if (settings.enabled && selectedSummary != null) {
      return _selectedCard(
        context: context,
        ref: ref,
        summary: selectedSummary,
        summaries: loadedSummaries,
        displaySettings: displaySettings,
      );
    }

    return summariesAsync.when(
      data: (summaries) {
        final selectableSummaries = summaries
            .where(_isSelectableRecordRaceSummary)
            .toList(growable: false);
        if (selectableSummaries.isEmpty) {
          return const RunRecordRaceCardShell(
            key: Key('record-race-recommendation-empty-card'),
            accent: AppColors.muted,
            title: '기록 레이스',
            message: '저장된 기록이 필요해요',
            detail: '경로가 있는 러닝을 저장하면 선택할 수 있어요.',
            enabled: false,
          );
        }

        final recommendationAsync = ref.watch(
          runRecordRaceRecommendationProvider,
        );
        return recommendationAsync.when(
          data: (recommendation) {
            if (recommendation == null) {
              return _fallbackCard(
                context: context,
                ref: ref,
                summaries: summaries,
              );
            }
            return _recommendationCard(
              context: context,
              ref: ref,
              recommendation: recommendation,
              summaries: summaries,
              displaySettings: displaySettings,
            );
          },
          loading: _loadingCard,
          error: (_, _) => _errorCard(),
        );
      },
      loading: _loadingCard,
      error: (_, _) => _errorCard(),
    );
  }

  Widget _recommendationCard({
    required BuildContext context,
    required WidgetRef ref,
    required RunRecordRaceRecommendation recommendation,
    required List<RunSessionSummary> summaries,
    required RunDisplaySettings displaySettings,
  }) {
    final summary = recommendation.summary;
    return RunRecordRaceCardShell(
      key: const Key('record-race-recommendation-card'),
      accent: AppColors.voltGreen,
      title: '오늘 추천',
      message: recordRaceRecommendationReasonLabel(recommendation.reason),
      detail: _metricsFor(summary, displaySettings),
      primaryLabel: '이 기록 선택',
      primaryKey: const Key('record-race-recommendation-select-button'),
      onPrimary: () =>
          selectRecordRaceSummary(context: context, ref: ref, summary: summary),
      secondaryLabel: '다른 기록',
      secondaryKey: const Key('record-race-recommendation-other-button'),
      onSecondary: () => openRecordRacePicker(
        context: context,
        ref: ref,
        summaries: summaries,
        recommendation: recommendation,
      ),
    );
  }

  Widget _selectedCard({
    required BuildContext context,
    required WidgetRef ref,
    required RunSessionSummary summary,
    required List<RunSessionSummary> summaries,
    required RunDisplaySettings displaySettings,
  }) {
    return RunRecordRaceCardShell(
      key: const Key('record-race-selected-card'),
      accent: AppColors.voltGreen,
      title: '기록 레이스',
      message: '경쟁레이스 · ${_metricsFor(summary, displaySettings)}',
      detail: '${summary.startedAt.month}/${summary.startedAt.day} 기록',
      primaryLabel: '변경',
      primaryKey: const Key('record-race-selected-change-button'),
      onPrimary: () => openRecordRacePicker(
        context: context,
        ref: ref,
        summaries: summaries.isEmpty ? null : summaries,
      ),
      secondaryLabel: '해제',
      secondaryKey: const Key('record-race-selected-clear-button'),
      onSecondary: ref.read(recordRaceSettingsProvider.notifier).disable,
    );
  }

  Widget _fallbackCard({
    required BuildContext context,
    required WidgetRef ref,
    required List<RunSessionSummary> summaries,
  }) {
    return RunRecordRaceCardShell(
      key: const Key('record-race-fallback-card'),
      accent: AppColors.voltGreen,
      title: '기록 레이스',
      message: '내 기록과 다시 달리기',
      detail: '저장된 러닝을 골라 비교하며 달려요.',
      primaryLabel: '기록 선택',
      primaryKey: const Key('record-race-fallback-select-button'),
      onPrimary: () => openRecordRacePicker(
        context: context,
        ref: ref,
        summaries: summaries,
      ),
    );
  }

  static Widget _loadingCard() {
    return const RunRecordRaceCardShell(
      key: Key('record-race-recommendation-loading-card'),
      accent: AppColors.muted,
      title: '기록 레이스',
      message: '기록을 확인하고 있어요.',
      enabled: false,
    );
  }

  static Widget _errorCard() {
    return const RunRecordRaceCardShell(
      key: Key('record-race-recommendation-error-card'),
      accent: AppColors.muted,
      title: '기록 레이스',
      message: '기록을 불러오지 못했어요.',
      enabled: false,
    );
  }

  static RunSessionSummary? _selectedSummary(
    RecordRaceSettingsState settings,
    List<RunSessionSummary> summaries,
  ) {
    final selectedSessionId = settings.selectedSessionId;
    if (!settings.enabled || selectedSessionId == null) {
      return null;
    }
    for (final summary in summaries) {
      if (summary.id == selectedSessionId) {
        return summary;
      }
    }
    return null;
  }

  static bool _isSelectableRecordRaceSummary(RunSessionSummary summary) {
    return summary.distanceM > 0 &&
        summary.durationMs > 0 &&
        summary.pointCount >= 2 &&
        summary.averagePaceSecPerKm.isFinite &&
        summary.averagePaceSecPerKm > 0;
  }

  static String _metricsFor(
    RunSessionSummary summary,
    RunDisplaySettings displaySettings,
  ) {
    final distance = formatRunDistance(
      summary.distanceM,
      displaySettings,
      decimals: 2,
    );
    final pace = formatRunPaceCompact(
      summary.averagePaceSecPerKm,
      displaySettings,
    );
    return '$distance · $pace';
  }
}

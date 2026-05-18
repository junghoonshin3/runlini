// 러닝 시작 전 오늘의 기록 레이스 추천 카드를 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/run_tracking/service/run_record_race_recommendation_service.dart';
import 'package:runlini/features/run_tracking/state/run_interval_providers.dart';
import 'package:runlini/features/run_tracking/state/run_record_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/run_training_mode_conflict_dialog.dart';

class RunRecordRaceRecommendationCard extends ConsumerWidget {
  const RunRecordRaceRecommendationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(recordRaceSettingsProvider);
    if (settings.enabled) {
      return const SizedBox.shrink();
    }

    final recommendationAsync = ref.watch(runRecordRaceRecommendationProvider);
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    return recommendationAsync.maybeWhen(
      data: (recommendation) {
        if (recommendation == null) {
          return const _RunRecordRaceRecommendationUnavailableCard();
        }
        return _RunRecordRaceRecommendationCardBody(
          recommendation: recommendation,
          displaySettings: displaySettings,
          onTap: () => _selectRecommendation(context, ref, recommendation),
        );
      },
      loading: () => const _RunRecordRaceRecommendationLoadingCard(),
      error: (_, _) => const _RunRecordRaceRecommendationUnavailableCard(
        message: '추천을 불러오지 못했어요.',
      ),
      orElse: () => const _RunRecordRaceRecommendationLoadingCard(),
    );
  }

  Future<void> _selectRecommendation(
    BuildContext context,
    WidgetRef ref,
    RunRecordRaceRecommendation recommendation,
  ) async {
    final runSettings =
        ref.read(runSettingsControllerProvider).value ??
        const RunSettingsState();
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

    ref
        .read(recordRaceSettingsProvider.notifier)
        .selectSession(recommendation.summary);
  }
}

class _RunRecordRaceRecommendationLoadingCard extends StatelessWidget {
  const _RunRecordRaceRecommendationLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _RunRecordRaceRecommendationShell(
      key: Key('record-race-recommendation-loading-card'),
      accent: AppColors.muted,
      title: '오늘 추천',
      message: '기록을 확인하고 있어요.',
      enabled: false,
    );
  }
}

class _RunRecordRaceRecommendationUnavailableCard extends StatelessWidget {
  const _RunRecordRaceRecommendationUnavailableCard({
    this.message = '경로 있는 기록을 저장하면 추천할게요.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return _RunRecordRaceRecommendationShell(
      key: const Key('record-race-recommendation-empty-card'),
      accent: AppColors.muted,
      title: '오늘 추천',
      message: message,
      enabled: false,
    );
  }
}

class _RunRecordRaceRecommendationCardBody extends StatelessWidget {
  const _RunRecordRaceRecommendationCardBody({
    required this.recommendation,
    required this.displaySettings,
    required this.onTap,
  });

  final RunRecordRaceRecommendation recommendation;
  final RunDisplaySettings displaySettings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = recommendation.summary;
    return _RunRecordRaceRecommendationShell(
      key: const Key('record-race-recommendation-card'),
      accent: AppColors.voltGreen,
      title: '오늘 추천',
      message: _titleFor(recommendation.reason),
      detail: _metricsFor(summary),
      onTap: onTap,
    );
  }

  String _titleFor(RunRecordRaceRecommendationReason reason) {
    return switch (reason) {
      RunRecordRaceRecommendationReason.sameWeekday => '같은 요일 기록으로 달리기',
      RunRecordRaceRecommendationReason.latest => '최근 기록으로 달리기',
    };
  }

  String _metricsFor(RunSessionSummary summary) {
    final distance = formatRunDistance(
      summary.distanceM,
      displaySettings,
      decimals: 2,
    );
    final pace = formatRunPaceCompact(
      summary.averagePaceSecPerKm,
      displaySettings,
    );
    return '$distance · $pace · ${summary.startedAt.month}/${summary.startedAt.day}';
  }
}

class _RunRecordRaceRecommendationShell extends StatelessWidget {
  const _RunRecordRaceRecommendationShell({
    super.key,
    required this.accent,
    required this.title,
    required this.message,
    this.detail,
    this.onTap,
    this.enabled = true,
  });

  final Color accent;
  final String title;
  final String message;
  final String? detail;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = enabled ? AppColors.chalk : AppColors.muted;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.9),
                border: Border.all(color: accent, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.labelLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (detail != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            detail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (enabled) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.voltGreen,
                      size: 28,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 러닝 시작 전 오늘의 기록 레이스 추천 카드를 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/run_tracking/service/run_record_race_recommendation_service.dart';
import 'package:runlini/features/run_tracking/state/run_record_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_picker_flow.dart';

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
          return const SizedBox.shrink();
        }
        return _RunRecordRaceRecommendationCardBody(
          recommendation: recommendation,
          displaySettings: displaySettings,
          onSelect: () => selectRecordRaceSummary(
            context: context,
            ref: ref,
            summary: recommendation.summary,
          ),
          onBrowseOther: () => openRecordRacePicker(
            context: context,
            ref: ref,
            recommendation: recommendation,
          ),
        );
      },
      loading: () => const _RunRecordRaceRecommendationLoadingCard(),
      error: (_, _) => const SizedBox.shrink(),
      orElse: () => const _RunRecordRaceRecommendationLoadingCard(),
    );
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

class _RunRecordRaceRecommendationCardBody extends StatelessWidget {
  const _RunRecordRaceRecommendationCardBody({
    required this.recommendation,
    required this.displaySettings,
    required this.onSelect,
    required this.onBrowseOther,
  });

  final RunRecordRaceRecommendation recommendation;
  final RunDisplaySettings displaySettings;
  final VoidCallback onSelect;
  final VoidCallback onBrowseOther;

  @override
  Widget build(BuildContext context) {
    final summary = recommendation.summary;
    return _RunRecordRaceRecommendationShell(
      key: const Key('record-race-recommendation-card'),
      accent: AppColors.voltGreen,
      title: '오늘 추천',
      message: _titleFor(recommendation.reason),
      detail: _metricsFor(summary),
      onSelect: onSelect,
      onBrowseOther: onBrowseOther,
    );
  }

  String _titleFor(RunRecordRaceRecommendationReason reason) {
    return recordRaceRecommendationReasonLabel(reason);
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
    this.onSelect,
    this.onBrowseOther,
    this.enabled = true,
  });

  final Color accent;
  final String title;
  final String message;
  final String? detail;
  final VoidCallback? onSelect;
  final VoidCallback? onBrowseOther;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = enabled ? AppColors.chalk : AppColors.muted;
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
                if (enabled) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key(
                            'record-race-recommendation-other-button',
                          ),
                          onPressed: onBrowseOther,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.chalk,
                            side: const BorderSide(
                              color: AppColors.chalk,
                              width: 2,
                            ),
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const FittedBox(child: Text('다른 기록')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          key: const Key(
                            'record-race-recommendation-select-button',
                          ),
                          onPressed: onSelect,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.voltGreen,
                            foregroundColor: AppColors.black,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const FittedBox(child: Text('이 기록 선택')),
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
}

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/run_session_detail_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_charts_section.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_record_race_comparison.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_route_preview.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_route_speed_tooltip.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_shoe_section.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_summary_sections.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_sync_status_section.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_actions.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_review_chrome.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class RunFinishReviewPanel extends StatelessWidget {
  const RunFinishReviewPanel({
    super.key,
    required this.session,
    this.onSave,
    this.onDiscard,
    this.onClose,
    this.onMore,
    this.onRetryHealthBackup,
    this.onManageShoe,
    this.displaySettings = const RunDisplaySettings(),
    this.privacySettings = const RunPrivacySettings(),
    this.shoeName,
    this.shoeImagePath,
    this.includePrimaryMetrics = true,
    this.showHeaderSummaryMetrics = true,
    this.showRouteSpeedTooltip = false,
    this.recordRaceSession,
    this.onSetBodyWeightForCalories,
  });

  final RunSession session;
  final VoidCallback? onSave;
  final VoidCallback? onDiscard;
  final VoidCallback? onClose;
  final VoidCallback? onMore;
  final VoidCallback? onRetryHealthBackup;
  final VoidCallback? onManageShoe;
  final RunDisplaySettings displaySettings;
  final RunPrivacySettings privacySettings;
  final String? shoeName;
  final String? shoeImagePath;
  final bool includePrimaryMetrics;
  final bool showHeaderSummaryMetrics;
  final bool showRouteSpeedTooltip;
  final RunSession? recordRaceSession;
  final VoidCallback? onSetBodyWeightForCalories;

  @override
  Widget build(BuildContext context) {
    final detail = const RunSessionDetailCalculator().calculate(
      session,
      splitDistanceM: splitDistanceMetersForDisplay(displaySettings),
    );
    return Container(
      key: const Key('run-finish-review-panel'),
      color: AppColors.black.withValues(alpha: 0.96),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width - 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RunReviewChrome(onClose: onClose, onMore: onMore),
                      const SizedBox(height: 18),
                      RunDetailHeader(
                        session: session,
                        detail: detail,
                        displaySettings: displaySettings,
                        showSummaryChips: showHeaderSummaryMetrics,
                      ),
                      const SizedBox(height: 14),
                      RunDetailMetricStrip(
                        detail: detail,
                        displaySettings: displaySettings,
                        privacySettings: privacySettings,
                        includePrimaryMetrics: includePrimaryMetrics,
                        onSetBodyWeightForCalories: onSetBodyWeightForCalories,
                      ),
                      if (privacySettings.hideStartEndArea) ...[
                        const SizedBox(height: 12),
                        const _PrivacyBadge(),
                      ],
                      if (session.recordRaceSummary != null) ...[
                        const SizedBox(height: 14),
                        RunDetailRecordRaceComparison(
                          session: session,
                          summary: session.recordRaceSummary!,
                          recordRaceSession: recordRaceSession,
                          displaySettings: displaySettings,
                        ),
                      ],
                      const SizedBox(height: 28),
                      _RouteSectionTitle(
                        showSpeedTooltip:
                            showRouteSpeedTooltip &&
                            !privacySettings.hideRouteMap,
                        points: session.points,
                        displaySettings: displaySettings,
                      ),
                      const SizedBox(height: 12),
                      if (privacySettings.hideRouteMap)
                        const _HiddenRoutePanel()
                      else
                        RunDetailRoutePreview(points: session.points),
                      const SizedBox(height: 38),
                      RunDetailChartsSection(
                        detail: detail,
                        displaySettings: displaySettings,
                        privacySettings: privacySettings,
                      ),
                      if (onManageShoe != null || shoeName != null) ...[
                        const SizedBox(height: 38),
                        RunDetailShoeSection(
                          shoeName: shoeName,
                          shoeImagePath: shoeImagePath,
                          onManageShoe: onManageShoe,
                        ),
                      ],
                      if (onSave == null && onDiscard == null) ...[
                        const SizedBox(height: 38),
                        RunDetailSyncStatusSection(
                          status: session.syncStatus,
                          recordSource: session.recordSource,
                          sourceSummary: session.sourceSummary,
                          onRetry: onRetryHealthBackup,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (onSave != null && onDiscard != null)
              RunFinishReviewActions(onSave: onSave!, onDiscard: onDiscard!),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDiscardFinishedRun(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('기록을 버릴까요?'),
        content: const Text('버린 러닝 기록은 복구할 수 없어요.'),
        actions: [
          TextButton(
            key: const Key('cancel-discard-run-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const Key('confirm-discard-run-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('버리기'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

class _PrivacyBadge extends StatelessWidget {
  const _PrivacyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('start-end-privacy-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('시작/종료 위치 보호 켜짐', style: _mutedTextStyle),
    );
  }
}

class _HiddenRoutePanel extends StatelessWidget {
  const _HiddenRoutePanel();

  @override
  Widget build(BuildContext context) {
    return const _HiddenDataPanel(
      key: Key('detail-route-hidden'),
      label: '경로 숨김',
    );
  }
}

class _HiddenDataPanel extends StatelessWidget {
  const _HiddenDataPanel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.13)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: _mutedTextStyle),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.chalk,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _RouteSectionTitle extends StatelessWidget {
  const _RouteSectionTitle({
    required this.showSpeedTooltip,
    required this.points,
    required this.displaySettings,
  });

  final bool showSpeedTooltip;
  final List<RunPoint> points;
  final RunDisplaySettings displaySettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SectionTitle('Route'),
        if (showSpeedTooltip) ...[
          const SizedBox(width: 4),
          RunDetailRouteSpeedInfoButton(
            points: points,
            displaySettings: displaySettings,
          ),
        ],
      ],
    );
  }
}

const _mutedTextStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w900,
);

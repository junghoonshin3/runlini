import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/service/run_session_detail_calculator.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_ghost_comparison.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_line_chart.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_route_preview.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_shoe_section.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_detail_splits_table.dart';
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
                      ),
                      const SizedBox(height: 14),
                      RunDetailMetricStrip(
                        detail: detail,
                        displaySettings: displaySettings,
                        privacySettings: privacySettings,
                      ),
                      if (onSave == null && onDiscard == null) ...[
                        const SizedBox(height: 12),
                        RunDetailSyncStatusSection(
                          status: session.syncStatus,
                          recordSource: session.recordSource,
                          sourceSummary: session.sourceSummary,
                          onRetry: onRetryHealthBackup,
                        ),
                      ],
                      if (privacySettings.hideStartEndArea) ...[
                        const SizedBox(height: 12),
                        const _PrivacyBadge(),
                      ],
                      if (session.ghostSummary != null) ...[
                        const SizedBox(height: 14),
                        RunDetailGhostComparison(
                          summary: session.ghostSummary!,
                          displaySettings: displaySettings,
                        ),
                      ],
                      const SizedBox(height: 28),
                      const _SectionTitle('Route'),
                      const SizedBox(height: 12),
                      if (privacySettings.hideRouteMap)
                        const _HiddenRoutePanel()
                      else
                        RunDetailRoutePreview(points: session.points),
                      const SizedBox(height: 38),
                      RunDetailLineChart(
                        title: 'Pace (${paceUnitLabel(displaySettings)})',
                        samples: detail.paceSamplesSecPerKm,
                        color: AppColors.cyan,
                        emptyLabel: '페이스 데이터가 아직 없어요.',
                        durationMs: detail.durationMs,
                        note: '낮을수록 빠른 페이스',
                        valueFormatter: (value) =>
                            formatRunPace(value, displaySettings),
                        summaryFormatter: (average, min, max) =>
                            'Avg ${formatRunPace(average, displaySettings)} · '
                            '${formatRunPace(min, displaySettings)}-'
                            '${formatRunPace(max, displaySettings)}',
                      ),
                      const SizedBox(height: 18),
                      RunDetailLineChart(
                        title: 'Speed',
                        samples: detail.speedSamplesKmh,
                        color: AppColors.cyan,
                        emptyLabel: '스피드 데이터가 아직 없어요.',
                        durationMs: detail.durationMs,
                        valueFormatter: (value) =>
                            formatRunSpeed(value, displaySettings),
                        summaryFormatter: (average, min, max) =>
                            'Avg ${formatRunSpeed(average, displaySettings)} · '
                            '${formatRunSpeed(min, displaySettings)}-'
                            '${formatRunSpeed(max, displaySettings)}',
                      ),
                      const SizedBox(height: 18),
                      RunDetailLineChart(
                        title: 'Elevation',
                        samples: detail.elevationSamplesM,
                        color: AppColors.voltGreen,
                        emptyLabel: '고도 데이터가 아직 없어요.',
                        durationMs: detail.durationMs,
                        valueFormatter: (value) =>
                            '${value.toStringAsFixed(1)} m',
                        summaryFormatter: (average, min, max) =>
                            'Avg ${average.toStringAsFixed(1)} m · '
                            '${min.toStringAsFixed(1)}-'
                            '${max.toStringAsFixed(1)} m',
                      ),
                      const SizedBox(height: 38),
                      RunDetailSplitsTable(
                        splits: detail.splits,
                        displaySettings: displaySettings,
                        privacySettings: privacySettings,
                      ),
                      const SizedBox(height: 18),
                      if (privacySettings.hideHeartRate)
                        const _HiddenDataPanel(label: 'Heart Rate Hidden')
                      else
                        RunDetailLineChart(
                          title: 'Heart Rate',
                          samples: detail.heartRateSamplesBpm,
                          color: AppColors.orange,
                          emptyLabel: '심박 데이터가 아직 없어요.',
                          durationMs: detail.durationMs,
                          valueFormatter: (value) => '${value.round()} bpm',
                          summaryFormatter: (average, min, max) =>
                              'Avg ${average.round()} bpm · '
                              '${min.round()}-${max.round()} bpm',
                        ),
                      if (onManageShoe != null || shoeName != null) ...[
                        const SizedBox(height: 38),
                        RunDetailShoeSection(
                          shoeName: shoeName,
                          shoeImagePath: shoeImagePath,
                          onManageShoe: onManageShoe,
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

const _mutedTextStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w900,
);

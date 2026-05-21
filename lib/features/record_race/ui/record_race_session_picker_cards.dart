// 기록 레이스 기록 선택 바텀시트의 접힘 카드와 확장 카드를 구성하는 위젯
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/record_race/ui/record_race_route_shape_preview.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

class CollapsedRecordRaceSessionCard extends StatelessWidget {
  const CollapsedRecordRaceSessionCard({
    super.key,
    required this.summary,
    required this.onTap,
    this.badgeLabel,
  });

  final RunSessionSummary summary;
  final VoidCallback onTap;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.muted, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatRecordRacePickerDate(summary.startedAt),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.chalk,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (badgeLabel != null) ...[
                          const SizedBox(width: 8),
                          _RecordRaceBadge(
                            label: badgeLabel!,
                            color: AppColors.muted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recordRacePickerSummaryLine(summary),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.chalk,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandedRecordRaceSessionCard extends StatelessWidget {
  const ExpandedRecordRaceSessionCard({
    super.key,
    required this.summary,
    required this.sessionAsync,
    required this.onSelect,
    this.badgeLabel,
    this.reasonLabel,
  });

  final RunSessionSummary summary;
  final AsyncValue<RunSession?> sessionAsync;
  final VoidCallback onSelect;
  final String? badgeLabel;
  final String? reasonLabel;

  @override
  Widget build(BuildContext context) {
    final session = sessionAsync.hasValue ? sessionAsync.value : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.voltGreen, width: 3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badgeLabel != null || reasonLabel != null) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                if (badgeLabel != null)
                  _RecordRaceBadge(
                    label: badgeLabel!,
                    color: AppColors.voltGreen,
                  ),
                if (reasonLabel != null)
                  Text(
                    reasonLabel!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.chalk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            formatRecordRacePickerDate(summary.startedAt),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RecordRaceMetric(
                  label: '거리',
                  value: recordRacePickerDistance(summary),
                ),
              ),
              Expanded(
                child: _RecordRaceMetric(
                  label: '시간',
                  value: recordRacePickerDuration(summary),
                ),
              ),
              Expanded(
                child: _RecordRaceMetric(
                  label: '평균',
                  value: recordRacePickerPace(summary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RecordRaceRouteShapePreview(
            points: session?.points,
            isLoading: sessionAsync.isLoading,
            errorMessage: sessionAsync.hasError ? '경로를 불러오지 못했어요.' : null,
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: Key('record-race-session-select-${summary.id}'),
            onPressed: onSelect,
            child: const Text('이 기록으로 달리기'),
          ),
        ],
      ),
    );
  }
}

class _RecordRaceMetric extends StatelessWidget {
  const _RecordRaceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 5),
        Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _RecordRaceBadge extends StatelessWidget {
  const _RecordRaceBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

String recordRacePickerSummaryLine(RunSessionSummary summary) {
  return '${recordRacePickerDistance(summary)} · ${recordRacePickerDuration(summary)} · '
      '${recordRacePickerPace(summary)}';
}

String recordRacePickerDistance(RunSessionSummary summary) {
  return formatRunDistance(summary.distanceM, const RunDisplaySettings());
}

String recordRacePickerDuration(RunSessionSummary summary) {
  final totalSeconds = summary.durationMs ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }
  return '$minutes:${_twoDigits(seconds)}';
}

String recordRacePickerPace(RunSessionSummary summary) {
  return formatRunPace(summary.averagePaceSecPerKm, const RunDisplaySettings());
}

String formatRecordRacePickerDate(DateTime startedAt) {
  return '${startedAt.year}.${_twoDigits(startedAt.month)}.'
      '${_twoDigits(startedAt.day)} '
      '${_twoDigits(startedAt.hour)}:${_twoDigits(startedAt.minute)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

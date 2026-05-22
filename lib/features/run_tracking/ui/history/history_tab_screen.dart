import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/app/ui/runlini_motion.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_session_detail_screen.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';
import 'package:runlini/features/run_tracking/ui/history/history_calendar_panel.dart';
import 'package:runlini/features/run_tracking/ui/history/history_distance_progress_panel.dart';
import 'package:runlini/features/run_tracking/ui/history/history_no_runs_on_date_panel.dart';
import 'package:runlini/features/run_tracking/ui/history/history_tab_skeleton.dart';
import 'package:runlini/features/run_tracking/ui/history/run_session_summary_tile.dart';

part 'history_tab_screen_sections.dart';

class HistoryTabScreen extends ConsumerStatefulWidget {
  const HistoryTabScreen({super.key, this.now});

  final DateTime? now;

  @override
  ConsumerState<HistoryTabScreen> createState() => _HistoryTabScreenState();
}

class _HistoryTabScreenState extends ConsumerState<HistoryTabScreen> {
  final Set<String> _deletedSessionIds = <String>{};
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _localDate(widget.now ?? DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final summariesAsync = ref.watch(runSessionSummaryListProvider);
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    final distanceGoals = ref.watch(runDistanceGoalSettingsProvider);
    final healthSyncState = ref.watch(healthSyncControllerProvider);
    final isHealthSyncing =
        healthSyncState.isLoading ||
        healthSyncState.value?.kind == HealthSyncStatusKind.syncing;

    return SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: RunliniMotion.enabledDuration(
          context,
          RunliniMotion.standardTransition,
        ),
        switchInCurve: RunliniMotion.enterCurve,
        switchOutCurve: RunliniMotion.exitCurve,
        child: summariesAsync.when(
          data: (List<RunSessionSummary> summaries) {
            final visibleSummaries = summaries
                .where((summary) => !_deletedSessionIds.contains(summary.id))
                .toList(growable: false);
            final filteredSummaries = visibleSummaries
                .where(
                  (RunSessionSummary summary) =>
                      _isSameDay(summary.startedAt, _selectedDate),
                )
                .toList(growable: false);
            final showRecovery = visibleSummaries.isEmpty;
            final today = widget.now ?? DateTime.now();
            final todaySummaries = visibleSummaries
                .where(
                  (RunSessionSummary summary) =>
                      _isSameDay(summary.startedAt, today),
                )
                .toList(growable: false);
            final todayDistanceM = todaySummaries.fold<double>(
              0,
              (double total, RunSessionSummary summary) =>
                  total + summary.distanceM,
            );
            final content = <Widget>[
              _HistoryHeader(
                todayDistanceM: todayDistanceM,
                todayRunCount: todaySummaries.length,
                displaySettings: displaySettings,
              ),
              HistoryDistanceProgressPanel(
                sessions: visibleSummaries,
                displaySettings: displaySettings,
                distanceGoals: distanceGoals,
                onChangeGoals: () {
                  ref.read(appTabProvider.notifier).setTab(AppTab.settings);
                },
              ),
              if (showRecovery)
                _HistoryRecoveryPanel(
                  isBusy: isHealthSyncing,
                  onRestoreFromHealth: _restoreHealthRecords,
                )
              else ...[
                HistoryCalendarPanel(
                  sessions: visibleSummaries,
                  displaySettings: displaySettings,
                  distanceGoals: distanceGoals,
                  selectedDate: _selectedDate,
                  now: widget.now,
                  onSelectedDate: (DateTime date) {
                    setState(() => _selectedDate = date);
                  },
                  onClearSelectedDate: () {
                    setState(
                      () => _selectedDate = _localDate(
                        widget.now ?? DateTime.now(),
                      ),
                    );
                  },
                ),
                _HistoryListLabel(selectedDate: _selectedDate),
                if (filteredSummaries.isEmpty)
                  const HistoryNoRunsOnDatePanel()
                else
                  for (final summary in filteredSummaries)
                    RunSessionSummaryTile(
                      key: Key('history-session-${summary.id}'),
                      summary: summary,
                      displaySettings: displaySettings,
                      onTap: () => _openDetail(context, summary),
                    ),
              ],
            ];
            return KeyedSubtree(
              key: const ValueKey<String>('history-data-state'),
              child: RefreshIndicator(
                key: const Key('history-refresh-indicator'),
                color: AppColors.voltGreen,
                backgroundColor: AppColors.black,
                onRefresh: _refreshHistory,
                child: SingleChildScrollView(
                  key: const Key('history-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _withHistorySpacing(content),
                  ),
                ),
              ),
            );
          },
          loading: () => const KeyedSubtree(
            key: ValueKey<String>('history-loading-state'),
            child: HistoryTabSkeleton(),
          ),
          error: (Object error, StackTrace stackTrace) => const KeyedSubtree(
            key: ValueKey<String>('history-error-state'),
            child: Center(child: Text('기록을 불러오지 못했어요.')),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreHealthRecords() async {
    final status = await ref
        .read(healthSyncControllerProvider.notifier)
        .syncWithUserAction();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_healthRestoreMessage(status)),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _refreshHistory() async {
    await ref.read(healthSyncControllerProvider.notifier).syncIfAuthorized();
    await ref
        .read(wearDraftSyncControllerProvider.notifier)
        .syncPendingDrafts();
    ref.invalidate(runSessionSummaryListProvider);
    await ref.read(runSessionSummaryListProvider.future);
  }

  Future<void> _openDetail(
    BuildContext context,
    RunSessionSummary summary,
  ) async {
    final session = await ref.read(runSessionByIdProvider(summary.id).future);
    if (session == null || !context.mounted) {
      return;
    }
    final result = await Navigator.of(context).push<RunSessionDetailResult>(
      MaterialPageRoute<RunSessionDetailResult>(
        builder: (BuildContext context) =>
            RunSessionDetailScreen(session: session),
      ),
    );
    if (result != null && mounted) {
      final messenger = ScaffoldMessenger.of(this.context);
      setState(() => _deletedSessionIds.add(result.sessionId));
      messenger.showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  String _healthRestoreMessage(HealthSyncStatus status) {
    return switch (status.kind) {
      HealthSyncStatusKind.synced => 'Health 기록 가져오기를 마쳤어요.',
      HealthSyncStatusKind.connectionNeeded => 'Health 권한이 필요해요.',
      HealthSyncStatusKind.unavailable => 'Health Connect 설치 또는 지원이 필요해요.',
      HealthSyncStatusKind.failed => 'Health 기록을 가져오지 못했어요.',
      HealthSyncStatusKind.idle ||
      HealthSyncStatusKind.syncing => 'Health 기록 가져오기를 마쳤어요.',
    };
  }
}

bool _isSameDay(DateTime left, DateTime right) {
  return _localDate(left) == _localDate(right);
}

DateTime _localDate(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

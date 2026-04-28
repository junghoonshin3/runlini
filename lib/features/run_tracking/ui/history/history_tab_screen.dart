import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_session_detail_screen.dart';
import 'package:runlini/features/run_tracking/ui/history/history_calendar_panel.dart';
import 'package:runlini/features/run_tracking/ui/history/history_distance_progress_panel.dart';
import 'package:runlini/features/run_tracking/ui/history/history_no_runs_on_date_panel.dart';
import 'package:runlini/features/run_tracking/ui/history/run_session_summary_tile.dart';

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
    final sessionsAsync = ref.watch(runSessionListProvider);
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    final distanceGoals = ref.watch(runDistanceGoalSettingsProvider);
    final healthSyncState = ref.watch(healthSyncControllerProvider);
    final isHealthSyncing =
        healthSyncState.isLoading ||
        healthSyncState.value?.kind == HealthSyncStatusKind.syncing;

    return SafeArea(
      bottom: false,
      child: sessionsAsync.when(
        data: (List<RunSession> sessions) {
          final visibleSessions = sessions
              .where((session) => !_deletedSessionIds.contains(session.id))
              .toList(growable: false);
          final filteredSessions = visibleSessions
              .where(
                (RunSession session) =>
                    _isSameDay(session.startedAt, _selectedDate),
              )
              .toList(growable: false);
          final showRecovery = visibleSessions.isEmpty;
          final content = <Widget>[
            const _HistoryHeader(),
            HistoryDistanceProgressPanel(
              sessions: visibleSessions,
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
                sessions: visibleSessions,
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
              if (filteredSessions.isEmpty)
                const HistoryNoRunsOnDatePanel()
              else
                for (final session in filteredSessions)
                  RunSessionSummaryTile(
                    key: Key('history-session-${session.id}'),
                    summary: RunSessionSummary.fromSession(session),
                    displaySettings: displaySettings,
                    onTap: () => _openDetail(context, session),
                  ),
            ],
          ];
          return RefreshIndicator(
            key: const Key('history-refresh-indicator'),
            color: AppColors.voltGreen,
            backgroundColor: AppColors.black,
            onRefresh: _refreshHistory,
            child: SingleChildScrollView(
              key: const Key('history-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _withHistorySpacing(content),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.voltGreen),
        ),
        error: (Object error, StackTrace stackTrace) =>
            const Center(child: Text('기록을 불러오지 못했어요.')),
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
    ref.invalidate(runSessionListProvider);
    await ref.read(runSessionListProvider.future);
  }

  Future<void> _openDetail(BuildContext context, RunSession session) async {
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
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

DateTime _localDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _selectedDateLabel(DateTime date) {
  return '${date.month}월 ${date.day}일 기록';
}

List<Widget> _withHistorySpacing(List<Widget> children) {
  return [
    for (var index = 0; index < children.length; index += 1) ...[
      if (index > 0) const SizedBox(height: 14),
      children[index],
    ],
  ];
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기록',
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 8),
        Text(
          '뛰었던 기록을 한눈에 보고 다음 고스트 기준선으로 고를 수 있게 정리해둡니다.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _HistoryRecoveryPanel extends StatelessWidget {
  const _HistoryRecoveryPanel({
    required this.isBusy,
    required this.onRestoreFromHealth,
  });

  final bool isBusy;
  final VoidCallback onRestoreFromHealth;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('health-restore-empty-panel'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.voltGreen.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('저장된 기록이 없어요', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '앱을 다시 설치했거나 데이터가 비어 있다면 Health Connect에서 최근 기록을 복구할 수 있어요.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 190,
            child: OutlinedButton(
              key: const Key('health-restore-settings-button'),
              onPressed: isBusy ? null : onRestoreFromHealth,
              child: Text(isBusy ? '처리 중...' : 'Health 기록 가져오기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryListLabel extends StatelessWidget {
  const _HistoryListLabel({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Text(
      _selectedDateLabel(selectedDate),
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

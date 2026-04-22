import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/ui/run_session_detail_screen.dart';
import 'package:runlini/features/run_tracking/ui/run_session_summary_tile.dart';

class HistoryTabScreen extends ConsumerStatefulWidget {
  const HistoryTabScreen({super.key});

  @override
  ConsumerState<HistoryTabScreen> createState() => _HistoryTabScreenState();
}

class _HistoryTabScreenState extends ConsumerState<HistoryTabScreen> {
  final Set<String> _deletedSessionIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(runSessionListProvider);

    return SafeArea(
      bottom: false,
      child: sessionsAsync.when(
        data: (List<RunSession> sessions) {
          final visibleSessions = sessions
              .where((session) => !_deletedSessionIds.contains(session.id))
              .toList(growable: false);
          return ListView.separated(
            key: const Key('history-list'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            itemCount: visibleSessions.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return const _HistoryHeader();
              }

              final session = visibleSessions[index - 1];
              final summary = RunSessionSummary.fromSession(session);
              return RunSessionSummaryTile(
                key: Key('history-session-${summary.id}'),
                summary: summary,
                onTap: () => _openDetail(context, session),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 14),
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

  Future<void> _openDetail(BuildContext context, RunSession session) async {
    final deletedSessionId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (BuildContext context) =>
            RunSessionDetailScreen(session: session),
      ),
    );
    if (deletedSessionId != null && mounted) {
      setState(() => _deletedSessionIds.add(deletedSessionId));
    }
  }
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

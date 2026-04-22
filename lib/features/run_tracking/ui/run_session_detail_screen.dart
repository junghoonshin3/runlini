import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/run_finish_review_panel.dart';

class RunSessionDetailScreen extends ConsumerWidget {
  const RunSessionDetailScreen({super.key, required this.session});

  final RunSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: RunFinishReviewPanel(
        key: const Key('history-run-detail-screen'),
        session: session,
        onClose: () => Navigator.of(context).maybePop(),
        onMore: () => _confirmDelete(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text('기록을 삭제할까요?'),
          content: const Text('삭제한 러닝 기록은 복구할 수 없어요.'),
          actions: [
            TextButton(
              key: const Key('cancel-delete-run-button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              key: const Key('confirm-delete-run-button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제하기'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(runSessionRepositoryProvider).deleteSession(session.id);
    if (context.mounted) {
      Navigator.of(context).pop(session.id);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/health/health_destination_labels.dart';
import 'package:runlini/core/health/health_workout_deleter.dart';
import 'package:runlini/core/health/health_workout_export_result.dart';
import 'package:runlini/features/health_sync/state/health_backup_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_form_screen.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_shoe_assignment_sheet.dart';

class RunSessionDetailScreen extends ConsumerWidget {
  const RunSessionDetailScreen({super.key, required this.session});

  final RunSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSession =
        ref.watch(runSessionByIdProvider(session.id)).value ?? session;
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    final privacySettings = ref.watch(runPrivacySettingsProvider);
    final recordRaceSummary = currentSession.recordRaceSummary;
    final recordRaceSession = recordRaceSummary == null
        ? null
        : ref
              .watch(
                runSessionByIdProvider(recordRaceSummary.recordRaceSessionId),
              )
              .value;
    final shoes = ref.watch(runShoeListProvider).value ?? const <RunShoe>[];
    final shoe = _shoeFor(currentSession, shoes);
    final shoeName = shoe == null ? null : '${shoe.brand} ${shoe.name}';
    return Scaffold(
      backgroundColor: AppColors.black,
      body: RunFinishReviewPanel(
        key: const Key('history-run-detail-screen'),
        session: currentSession,
        displaySettings: displaySettings,
        privacySettings: privacySettings,
        shoeName: shoeName,
        shoeImagePath: shoe?.imagePath,
        showHeaderSummaryMetrics: false,
        showRouteSpeedTooltip: true,
        recordRaceSession: recordRaceSession,
        onClose: () => Navigator.of(context).maybePop(),
        onMore: () => _confirmDelete(context, ref, currentSession),
        onRetryHealthBackup: _canSendToHealth(currentSession)
            ? () => _retryHealthBackup(context, ref, currentSession)
            : null,
        onManageShoe: () => _manageShoe(context, ref, currentSession, shoes),
      ),
    );
  }

  RunShoe? _shoeFor(RunSession session, List<RunShoe> shoes) {
    final shoeId = session.shoeId;
    if (shoeId == null) {
      return null;
    }
    for (final shoe in shoes) {
      if (shoe.id == shoeId) {
        return shoe;
      }
    }
    return null;
  }

  bool _canSendToHealth(RunSession session) {
    return session.recordSource == RunSessionRecordSource.appLocal &&
        session.syncStatus != RunSessionSyncStatus.synced;
  }

  Future<void> _manageShoe(
    BuildContext context,
    WidgetRef ref,
    RunSession session,
    List<RunShoe> shoes,
  ) async {
    final activeShoes = shoes
        .where((shoe) => !shoe.retired && !shoe.deleted)
        .toList(growable: false);
    final result = await showModalBottomSheet<RunShoeAssignmentResult>(
      context: context,
      backgroundColor: AppColors.panel,
      showDragHandle: true,
      builder: (context) => RunShoeAssignmentSheet(
        shoes: activeShoes,
        currentShoeId: session.shoeId,
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }

    final selectedShoe = result.isAddNew
        ? await Navigator.of(context).push<RunShoe>(
            MaterialPageRoute<RunShoe>(
              builder: (context) => const RunShoeFormScreen(),
            ),
          )
        : result.shoe;
    if (selectedShoe == null || !context.mounted) {
      return;
    }
    await _assignShoe(context, ref, session, selectedShoe);
  }

  Future<void> _assignShoe(
    BuildContext context,
    WidgetRef ref,
    RunSession session,
    RunShoe shoe,
  ) async {
    await ref
        .read(runSessionRepositoryProvider)
        .saveSession(session.copyWith(shoeId: shoe.id));
    ref.invalidate(runSessionListProvider);
    ref.invalidate(runSessionSummaryListProvider);
    ref.invalidate(runSessionByIdProvider(session.id));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${shoe.brand} ${shoe.name}에 기록을 연결했어요.')),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RunSession session,
  ) async {
    final choice = await showDialog<_DeleteRunChoice>(
      context: context,
      builder: (BuildContext context) {
        var deleteFromHealth = false;
        return AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text('기록을 삭제할까요?'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('기본적으로 Runlini에서만 삭제돼요. Health 기록은 유지됩니다.'),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      key: const Key('delete-health-source-checkbox'),
                      value: deleteFromHealth,
                      onChanged: (bool? value) {
                        setState(() => deleteFromHealth = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Health에서도 영구 삭제'),
                      subtitle: const Text(
                        'Health Connect / Apple 건강에 저장된 원본 기록도 삭제를 시도해요.',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              key: const Key('cancel-delete-run-button'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              key: const Key('confirm-delete-run-button'),
              onPressed: () => Navigator.of(
                context,
              ).pop(_DeleteRunChoice(deleteFromHealth: deleteFromHealth)),
              child: const Text('삭제하기'),
            ),
          ],
        );
      },
    );
    if (choice == null || !context.mounted) {
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    final canDeleteHealth =
        session.externalId != null &&
        session.syncStatus == RunSessionSyncStatus.synced;
    final deletedFromHealth = choice.deleteFromHealth && canDeleteHealth
        ? await ref
              .read(healthWorkoutDeleterProvider)
              .deleteWorkout(
                externalId: session.externalId,
                startedAt: session.startedAt,
                endedAt: session.endedAt ?? _endedAt(session),
              )
        : false;
    await ref.read(runSessionRepositoryProvider).deleteSession(session.id);
    if (context.mounted) {
      Navigator.of(context).pop(
        RunSessionDetailResult.deleted(
          sessionId: session.id,
          message: _deleteMessage(
            requestedHealthDelete: choice.deleteFromHealth,
            canDeleteHealth: canDeleteHealth,
            deletedFromHealth: deletedFromHealth,
          ),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.invalidate(runSessionListProvider);
        container.invalidate(runSessionSummaryListProvider);
        container.invalidate(runSessionByIdProvider(session.id));
      });
    }
  }

  DateTime _endedAt(RunSession session) {
    return session.startedAt.add(Duration(milliseconds: session.durationMs));
  }

  String _deleteMessage({
    required bool requestedHealthDelete,
    required bool canDeleteHealth,
    required bool deletedFromHealth,
  }) {
    if (!requestedHealthDelete) {
      return 'Runlini에서 삭제됨';
    }
    if (!canDeleteHealth) {
      return 'Runlini에서 삭제됨 · Health 원본을 특정할 수 없어요';
    }
    return deletedFromHealth
        ? 'Runlini와 Health에서 삭제됨'
        : 'Runlini에서 삭제됨 · Health 삭제 실패';
  }

  Future<void> _retryHealthBackup(
    BuildContext context,
    WidgetRef ref,
    RunSession session,
  ) async {
    final result = await ref
        .read(healthBackupControllerProvider.notifier)
        .retrySession(session);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_backupMessage(result))));
  }

  String _backupMessage(HealthWorkoutExportResult result) {
    final target = healthDestinationSendTarget(defaultTargetPlatform);
    return switch (result.kind) {
      HealthWorkoutExportResultKind.synced => '$target 보냈어요.',
      HealthWorkoutExportResultKind.skipped => '$target 보내지 못했어요.',
      HealthWorkoutExportResultKind.failed => '$target 보내지 못했어요.',
    };
  }
}

class _DeleteRunChoice {
  const _DeleteRunChoice({required this.deleteFromHealth});

  final bool deleteFromHealth;
}

class RunSessionDetailResult {
  const RunSessionDetailResult.deleted({
    required this.sessionId,
    required this.message,
  });

  final String sessionId;
  final String message;
}

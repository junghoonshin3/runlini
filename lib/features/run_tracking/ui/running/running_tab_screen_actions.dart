part of 'running_tab_screen.dart';

extension _RunningTabScreenActions on _RunningTabScreenState {
  Future<void> _handleStartStopPressed({
    required BuildContext context,
    required RunPlaybackState playbackState,
  }) async {
    if (playbackState.hasActiveSession) {
      await _stopActiveRunWithRecordRaceSummary();
      return;
    }

    if (_startFlowInProgress) {
      return;
    }

    if (!await _resolveRecordRaceIntervalConflict(context)) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    if (!await _ensureRecordRaceRunAccuracy(context)) {
      return;
    }

    _startFlowInProgress = true;
    try {
      final result = await ref
          .read(runStartCountdownControllerProvider.notifier)
          .startAfterCountdown(
            onStart: ref.read(runPlaybackControllerProvider.notifier).start,
          );
      if (!context.mounted || result != RunTrackingToggleResult.unavailable) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('러닝 위치 추적을 시작하지 못했어요. GPS와 위치 권한을 확인해 주세요.'),
        ),
      );
    } finally {
      _startFlowInProgress = false;
    }
  }

  Future<bool> _resolveRecordRaceIntervalConflict(BuildContext context) async {
    if (!_hasSelectedRecordRaceRun()) {
      return true;
    }

    final runSettings =
        ref.read(runSettingsControllerProvider).value ??
        const RunSettingsState();
    final intervalWorkout = runSettings.intervalWorkout;
    if (!isRunIntervalEnabledForRuntime(intervalWorkout)) {
      return true;
    }

    final confirmed = await confirmDisableIntervalForRecordRace(context);
    if (!context.mounted || !confirmed) {
      return false;
    }
    await ref
        .read(runSettingsControllerProvider.notifier)
        .setIntervalWorkout(intervalWorkout.copyWith(enabled: false));
    return true;
  }

  Future<bool> _ensureRecordRaceRunAccuracy(BuildContext context) async {
    if (!_hasSelectedRecordRaceRun()) {
      return true;
    }

    final runSettings =
        ref.read(runSettingsControllerProvider).value ??
        const RunSettingsState();
    if (runSettings.locationTrackingPreset ==
        RunLocationTrackingPreset.highAccuracy) {
      return true;
    }

    final goToSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const Key('record-race-run-accuracy-dialog'),
          backgroundColor: AppColors.panel,
          title: const Text('기록 레이스는 정확한 위치가 필요해요'),
          content: const Text('기록 레이스와 비교하려면 위치 업데이트를 정확으로 설정해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              key: const Key('record-race-run-accuracy-settings-button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
    if (!context.mounted) {
      return false;
    }
    if (goToSettings == true) {
      ref.read(appTabProvider.notifier).setTab(AppTab.settings);
    }
    return false;
  }

  bool _hasSelectedRecordRaceRun() {
    final recordRaceSettings = ref.read(recordRaceSettingsProvider);
    return ref
                .read(runMapStaticStateProvider)
                .value
                ?.selectedRecordRaceSession !=
            null ||
        (recordRaceSettings.enabled &&
            recordRaceSettings.selectedSessionId != null);
  }

  Future<void> _stopActiveRunWithRecordRaceSummary({
    RunSessionRecordRaceSummary? preferredRecordRaceSummary,
  }) async {
    final recordRaceFrame = ref.read(recordRaceFrameProvider);
    final selectedRecordRaceSession = ref
        .read(runMapStaticStateProvider)
        .value
        ?.selectedRecordRaceSession;
    final completionSummary = ref
        .read(runPlaybackControllerProvider)
        .recordRaceCompletionSummary;
    await ref
        .read(runPlaybackControllerProvider.notifier)
        .stop(
          recordRaceSummary:
              preferredRecordRaceSummary ??
              completionSummary ??
              runSessionRecordRaceSummaryFromFrame(
                recordRaceFrame,
                selectedRecordRaceSession,
              ),
        );
  }

  Future<void> _handlePauseResumePressed({
    required RunPlaybackState playbackState,
  }) async {
    final controller = ref.read(runPlaybackControllerProvider.notifier);
    if (playbackState.status == RunScreenStatus.running) {
      await controller.pause();
      return;
    }

    if (playbackState.status == RunScreenStatus.paused) {
      await controller.resume();
    }
  }

  Future<void> _handleCurrentLocationPressed(BuildContext context) async {
    final locationController = ref.read(liveLocationProvider.notifier);
    final location = await locationController.prepareQuickRecenterTarget();
    if (!context.mounted) {
      return;
    }
    if (location != null) {
      ref.read(runMapRecenterTickProvider.notifier).trigger();
      return;
    }

    final freshLocation = await locationController.refresh();
    if (!context.mounted) {
      return;
    }
    if (freshLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치를 가져오지 못했어요. GPS와 위치 권한을 확인해 주세요.')),
      );
      return;
    }
    ref.read(runMapRecenterTickProvider.notifier).trigger();
  }

  Future<void> _handleSaveFinishedRun() async {
    await saveFinishedRunWithFeedback(context, ref);
  }

  Future<void> _handleDiscardFinishedRun(BuildContext context) async {
    if (!await confirmDiscardFinishedRun(context)) {
      return;
    }
    await ref.read(runPlaybackControllerProvider.notifier).discardFinishedRun();
  }
}

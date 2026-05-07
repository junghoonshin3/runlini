part of 'running_tab_screen.dart';

extension _RunningTabScreenActions on _RunningTabScreenState {
  Future<void> _handleStartStopPressed({
    required BuildContext context,
    required RunPlaybackState playbackState,
  }) async {
    if (playbackState.hasActiveSession) {
      await _stopActiveRunWithGhostSummary();
      return;
    }

    if (_startFlowInProgress) {
      return;
    }

    if (!await _resolveGhostIntervalConflict(context)) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    if (!await _ensureGhostRunAccuracy(context)) {
      return;
    }

    _startFlowInProgress = true;
    try {
      final result = await ref
          .read(runStartCountdownControllerProvider.notifier)
          .startAfterCountdown(
            onStart: ref.read(runPlaybackControllerProvider.notifier).start,
          );
      if (result == RunTrackingToggleResult.started) {
        _speakGhostRunStartCueIfNeeded();
        return;
      }
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

  void _speakGhostRunStartCueIfNeeded() {
    final settings =
        ref.read(runSettingsControllerProvider).value ??
        const RunSettingsState();
    final cue = _voiceCueCoordinator.ghostStartCueFor(
      isGhostRun: _hasSelectedGhostRun(),
      settings: settings,
    );
    if (cue == null) {
      return;
    }
    unawaited(_speakRunVoiceCues(<RunVoiceCue>[cue]));
  }

  Future<bool> _resolveGhostIntervalConflict(BuildContext context) async {
    if (!_hasSelectedGhostRun()) {
      return true;
    }

    final runSettings =
        ref.read(runSettingsControllerProvider).value ??
        const RunSettingsState();
    final intervalWorkout = runSettings.intervalWorkout;
    if (!intervalWorkout.enabled) {
      return true;
    }

    final confirmed = await confirmDisableIntervalForGhost(context);
    if (!context.mounted || !confirmed) {
      return false;
    }
    await ref
        .read(runSettingsControllerProvider.notifier)
        .setIntervalWorkout(intervalWorkout.copyWith(enabled: false));
    return true;
  }

  Future<bool> _ensureGhostRunAccuracy(BuildContext context) async {
    if (!_hasSelectedGhostRun()) {
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
          key: const Key('ghost-run-accuracy-dialog'),
          backgroundColor: AppColors.panel,
          title: const Text('고스트런은 정확한 위치가 필요해요'),
          content: const Text('고스트와 비교하려면 위치 업데이트를 정확으로 설정해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              key: const Key('ghost-run-accuracy-settings-button'),
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

  bool _hasSelectedGhostRun() {
    final ghostSettings = ref.read(ghostSettingsProvider);
    return ref.read(runMapStaticStateProvider).value?.selectedGhostSession !=
            null ||
        (ghostSettings.enabled && ghostSettings.selectedSessionId != null);
  }

  Future<void> _stopActiveRunWithGhostSummary({
    RunSessionGhostSummary? preferredGhostSummary,
  }) async {
    final ghostFrame = ref.read(ghostRaceFrameProvider);
    final selectedGhostSession = ref
        .read(runMapStaticStateProvider)
        .value
        ?.selectedGhostSession;
    final completionSummary = ref
        .read(runPlaybackControllerProvider)
        .ghostCompletionSummary;
    await ref
        .read(runPlaybackControllerProvider.notifier)
        .stop(
          ghostSummary:
              preferredGhostSummary ??
              completionSummary ??
              runSessionGhostSummaryFromFrame(ghostFrame, selectedGhostSession),
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

part of 'running_tab_screen.dart';

extension _RunningTabScreenActions on _RunningTabScreenState {
  Future<void> _handleStartStopPressed({
    required BuildContext context,
    required RunPlaybackState playbackState,
  }) async {
    if (playbackState.hasActiveSession) {
      final ghostFrame = ref.read(ghostRaceFrameProvider);
      final selectedGhostSession = ref
          .read(runMapStaticStateProvider)
          .value
          ?.selectedGhostSession;
      await ref
          .read(runPlaybackControllerProvider.notifier)
          .stop(
            ghostSummary: runSessionGhostSummaryFromFrame(
              ghostFrame,
              selectedGhostSession,
            ),
          );
      return;
    }

    if (_startFlowInProgress) {
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

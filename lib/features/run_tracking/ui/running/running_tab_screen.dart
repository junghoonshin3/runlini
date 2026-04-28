import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/run_tracking/state/run_ghost_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_metrics_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/run_control_buttons.dart';
import 'package:runlini/features/run_tracking/ui/running/run_finish_review_overlay.dart';
import 'package:runlini/features/run_tracking/ui/running/run_ghost_control_chip.dart';
import 'package:runlini/features/run_tracking/ui/running/run_map_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/run_save_feedback.dart';
import 'package:runlini/features/run_tracking/ui/running/run_session_ghost_summary_mapper.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');

class RunningTabScreen extends ConsumerStatefulWidget {
  const RunningTabScreen({super.key});

  @override
  ConsumerState<RunningTabScreen> createState() => _RunningTabScreenState();
}

class _RunningTabScreenState extends ConsumerState<RunningTabScreen> {
  bool _initialLocationBootstrapComplete = false;
  bool _startFlowInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final deviceLocationClient = ref.read(deviceLocationClientProvider);
      if (_isFlutterTest &&
          deviceLocationClient is GeolocatorRunLocationClient) {
        setState(() {
          _initialLocationBootstrapComplete = true;
        });
        return;
      }

      final locationController = ref.read(liveLocationProvider.notifier);
      try {
        await locationController.bootstrapInitialLocation();
      } catch (error) {
        debugPrint('Runlini initial location bootstrap skipped: $error');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLocationBootstrapComplete = true;
      });
      try {
        await locationController.syncTracking();
      } catch (error) {
        debugPrint('Runlini live location startup skipped: $error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapViewState = ref.watch(ghostAwareRunMapViewStateProvider);
    final playbackState = ref.watch(runPlaybackControllerProvider);
    final liveRunMetrics = ref.watch(liveRunMetricsProvider);
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    final ghostRaceFrame = ref.watch(ghostRaceFrameProvider);
    final countdownState = ref.watch(runStartCountdownControllerProvider);
    final pendingFinishedSession = playbackState.pendingFinishedSession;
    final isReviewing = playbackState.isReviewing;

    if (!_initialLocationBootstrapComplete || mapViewState == null) {
      final mapStaticStateAsync = ref.read(runMapStaticStateProvider);
      return SafeArea(
        bottom: false,
        child: _initialLocationBootstrapComplete && mapStaticStateAsync.hasError
            ? const Center(child: Text('러닝 지도를 준비하지 못했어요.'))
            : const Center(
                child: CircularProgressIndicator(color: AppColors.voltGreen),
              ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned.fill(child: RunMapPanel(mapViewState: mapViewState)),
          if (playbackState.hasActiveSession && liveRunMetrics != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: LiveRunMetricsPanel(
                metrics: liveRunMetrics,
                displaySettings: displaySettings,
                ghostRace: ghostRaceFrame,
              ),
            ),
          if (!isReviewing) ...[
            Positioned(
              left: 20,
              bottom: 28,
              child: playbackState.hasActiveSession
                  ? RunPauseResumeButton(
                      isPaused: playbackState.status == RunScreenStatus.paused,
                      onPressed: () async {
                        await _handlePauseResumePressed(
                          playbackState: playbackState,
                        );
                      },
                    )
                  : RunSettingsButton(
                      onPressed: () {
                        ref
                            .read(appTabProvider.notifier)
                            .setTab(AppTab.settings);
                      },
                    ),
            ),
            if (!playbackState.hasActiveSession && !countdownState.isActive)
              const Positioned(
                left: 20,
                right: 20,
                bottom: 156,
                child: RunGhostControlChip(),
              ),
            Positioned(
              right: 20,
              bottom: 28,
              child: RunCurrentLocationButton(
                onPressed: () async {
                  await _handleCurrentLocationPressed(context);
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: RunStartStopButton(
                  showsStopAction: playbackState.hasActiveSession,
                  onPressed: () async {
                    await _handleStartStopPressed(
                      context: context,
                      playbackState: playbackState,
                    );
                  },
                ),
              ),
            ),
          ],
          if (isReviewing && pendingFinishedSession != null)
            Positioned.fill(
              child: RunFinishReviewOverlay(
                session: pendingFinishedSession,
                onSave: () async {
                  await _handleSaveFinishedRun();
                },
                onDiscard: () async {
                  await _handleDiscardFinishedRun(context);
                },
              ),
            ),
        ],
      ),
    );
  }

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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/state/run_ghost_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/state/run_voice_cue_providers.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_interval_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_metrics_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/run_control_buttons.dart';
import 'package:runlini/features/run_tracking/ui/running/run_finish_review_overlay.dart';
import 'package:runlini/features/run_tracking/ui/running/run_ghost_control_chip.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet.dart';
import 'package:runlini/features/run_tracking/ui/running/run_map_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/run_save_feedback.dart';
import 'package:runlini/features/run_tracking/ui/running/run_session_ghost_summary_mapper.dart';

part 'running_tab_screen_actions.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');

class RunningTabScreen extends ConsumerStatefulWidget {
  const RunningTabScreen({super.key});

  @override
  ConsumerState<RunningTabScreen> createState() => _RunningTabScreenState();
}

class _RunningTabScreenState extends ConsumerState<RunningTabScreen> {
  final RunVoiceCueCoordinator _voiceCueCoordinator = RunVoiceCueCoordinator();
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
    final intervalFrame = ref.watch(runIntervalFrameProvider);
    final countdownState = ref.watch(runStartCountdownControllerProvider);
    final settings =
        ref.watch(runSettingsControllerProvider).value ??
        const RunSettingsState();
    final pendingFinishedSession = playbackState.pendingFinishedSession;
    final isReviewing = playbackState.isReviewing;

    _listenForRunVoiceCues();

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (intervalFrame != null) ...[
                    LiveRunIntervalPanel(
                      frame: intervalFrame,
                      onAdvance: ref
                          .read(runPlaybackControllerProvider.notifier)
                          .advanceInterval,
                    ),
                    const SizedBox(height: 10),
                  ],
                  LiveRunMetricsPanel(
                    metrics: liveRunMetrics,
                    displaySettings: displaySettings,
                    ghostRace: ghostRaceFrame,
                  ),
                ],
              ),
            ),
          if (!isReviewing) ...[
            if (playbackState.hasActiveSession || !countdownState.isActive)
              Positioned(
                left: 20,
                bottom: 28,
                child: playbackState.hasActiveSession
                    ? RunPauseResumeButton(
                        isPaused:
                            playbackState.status == RunScreenStatus.paused,
                        onPressed: () async {
                          await _handlePauseResumePressed(
                            playbackState: playbackState,
                          );
                        },
                      )
                    : RunIntervalButton(
                        workout: settings.intervalWorkout,
                        onPressed: () => showRunIntervalSheet(context, ref),
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

  void _listenForRunVoiceCues() {
    ref.listen(runVoiceCueSnapshotProvider, (previous, next) {
      final cues = _voiceCueCoordinator.cuesFor(next);
      if (cues.isEmpty) {
        return;
      }
      unawaited(_speakRunVoiceCues(cues));
    });
  }

  Future<void> _speakRunVoiceCues(List<RunVoiceCue> cues) async {
    final client = ref.read(runVoiceCueClientProvider);
    for (final cue in cues) {
      await client.speak(cue.text, volume: cue.volume);
    }
  }
}

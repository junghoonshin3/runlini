import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_config_client.dart';
import 'package:runlini/core/performance/startup_trace.dart';
import 'package:runlini/core/voice/run_voice_cue_client.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_dispatcher.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_record_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/state/run_voice_cue_providers.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_session_record_race_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/detail/run_finish_review_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/live_run_dashboard_overlay.dart';
import 'package:runlini/features/run_tracking/ui/running/run_control_buttons.dart';
import 'package:runlini/features/run_tracking/ui/running/run_finish_review_overlay.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet.dart';
import 'package:runlini/features/run_tracking/ui/running/run_map_panel.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_completion_overlay.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_control_chip.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_recommendation_card.dart';
import 'package:runlini/features/run_tracking/ui/running/run_save_feedback.dart';
import 'package:runlini/features/run_tracking/ui/running/run_session_record_race_summary_mapper.dart';
import 'package:runlini/features/run_tracking/ui/running/run_training_mode_conflict_dialog.dart';

part 'running_tab_screen_actions.dart';
part 'running_tab_screen_record_race_completion.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');

class RunningTabScreen extends ConsumerStatefulWidget {
  const RunningTabScreen({super.key});

  @override
  ConsumerState<RunningTabScreen> createState() => _RunningTabScreenState();
}

class _RunningTabScreenState extends ConsumerState<RunningTabScreen> {
  final RunVoiceCueCoordinator _voiceCueCoordinator = RunVoiceCueCoordinator();
  final RunVoiceCueDispatcher _voiceCueDispatcher = RunVoiceCueDispatcher();
  late final RunVoiceCueClient _voiceCueClient;
  ProviderSubscription<RunVoiceCueSnapshot>? _voiceCueSubscription;
  ProviderSubscription<RecordRaceFrame?>? _recordRaceCompletionSubscription;
  String? _recordRaceCompletionSessionId;
  int _recordRaceCompletionCandidateCount = 0;
  bool _recordRaceCompletionWriteQueued = false;
  bool _startFlowInProgress = false;

  @override
  void initState() {
    super.initState();
    _voiceCueClient = ref.read(runVoiceCueClientProvider);
    _voiceCueSubscription = ref.listenManual<RunVoiceCueSnapshot>(
      runVoiceCueSnapshotProvider,
      (previous, next) => _handleRunVoiceCueSnapshot(next),
    );
    _recordRaceCompletionSubscription = ref.listenManual<RecordRaceFrame?>(
      recordRaceFrameProvider,
      (previous, next) => _handleRecordRaceCompletionFrame(next),
    );
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
        await StartupTrace.measure(
          'location bootstrap',
          locationController.bootstrapInitialLocation,
        );
      } catch (error) {
        debugPrint('Runlini initial location bootstrap skipped: $error');
      }
      if (!mounted) {
        return;
      }
      try {
        await StartupTrace.measure(
          'location tracking startup',
          locationController.syncTracking,
        );
      } catch (error) {
        debugPrint('Runlini live location startup skipped: $error');
      }
    });
  }

  @override
  void dispose() {
    _voiceCueSubscription?.close();
    _recordRaceCompletionSubscription?.close();
    unawaited(_voiceCueDispatcher.stop(_voiceCueClient));
    _voiceCueCoordinator.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapViewState = ref.watch(recordRaceAwareRunMapViewStateProvider);
    final playbackState = ref.watch(runPlaybackControllerProvider);
    final liveRunMetrics = ref.watch(liveRunMetricsProvider);
    final displaySettings = ref.watch(runDisplaySettingsProvider);
    final recordRaceFrame = ref.watch(recordRaceFrameProvider);
    final intervalFrame = ref.watch(runIntervalFrameProvider);
    final countdownState = ref.watch(runStartCountdownControllerProvider);
    final mapControlsReady = ref.watch(runMapControlsReadyProvider);
    final settings =
        ref.watch(runSettingsControllerProvider).value ??
        const RunSettingsState();
    final intervalWorkout = effectiveRunIntervalWorkout(
      settings.intervalWorkout,
    );
    final pendingFinishedSession = playbackState.pendingFinishedSession;
    final isReviewing = playbackState.isReviewing;
    final recordRaceCompletionSummary =
        playbackState.recordRaceCompletionSummary;

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned.fill(child: RunMapPanel(mapViewState: mapViewState)),
          if (mapControlsReady &&
              playbackState.hasActiveSession &&
              liveRunMetrics != null)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: LiveRunDashboardOverlay(
                key: ValueKey(
                  'live-dashboard-${playbackState.activeSessionId}',
                ),
                sessionId: playbackState.activeSessionId,
                metrics: liveRunMetrics,
                displaySettings: displaySettings,
                recordRaceCompleted: recordRaceCompletionSummary != null,
                recordRace: recordRaceFrame,
                intervalFrame: intervalFrame,
                onAdvanceInterval: ref
                    .read(runPlaybackControllerProvider.notifier)
                    .advanceInterval,
              ),
            ),
          if (mapControlsReady && !isReviewing) ...[
            if (!playbackState.hasActiveSession && !countdownState.isActive)
              const Positioned(
                top: 12,
                left: 20,
                right: 20,
                child: RunRecordRaceRecommendationCard(),
              ),
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
                        workout: intervalWorkout,
                        onPressed: () => _handleIntervalButtonPressed(context),
                      ),
              ),
            if (!playbackState.hasActiveSession && !countdownState.isActive)
              const Positioned(
                left: 20,
                right: 20,
                bottom: 156,
                child: RunRecordRaceControlChip(),
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
          if (playbackState.recordRaceCompletionPromptPending &&
              recordRaceCompletionSummary != null &&
              !isReviewing)
            Positioned.fill(
              child: RunRecordRaceCompletionOverlay(
                summary: recordRaceCompletionSummary,
                onContinue: () {
                  ref
                      .read(runPlaybackControllerProvider.notifier)
                      .continueAfterRecordRaceCompletion();
                },
                onStop: () async {
                  await _stopActiveRunWithRecordRaceSummary(
                    preferredRecordRaceSummary: recordRaceCompletionSummary,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _handleRunVoiceCueSnapshot(RunVoiceCueSnapshot snapshot) {
    final cues = _voiceCueCoordinator.cuesFor(snapshot);
    if (cues.isEmpty) {
      if (_shouldStopVoiceCuePlayback(snapshot)) {
        unawaited(_voiceCueDispatcher.stop(_voiceCueClient));
      }
      return;
    }
    _voiceCueDispatcher.enqueue(cues, _voiceCueClient);
  }

  bool _shouldStopVoiceCuePlayback(RunVoiceCueSnapshot snapshot) {
    final metrics = snapshot.metrics;
    return !snapshot.playbackState.hasActiveSession ||
        snapshot.playbackState.status != RunScreenStatus.running ||
        metrics == null ||
        metrics.isPaused ||
        !snapshot.settings.voiceCueEnabled;
  }

  void _handleIntervalButtonPressed(BuildContext context) {
    if (!runIntervalFeatureLocked) {
      showRunIntervalSheet(context, ref);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text(runIntervalFeatureLockedMessage)),
    );
  }
}

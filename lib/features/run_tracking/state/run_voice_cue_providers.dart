import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/voice/run_voice_cue_client.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/state/run_ghost_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

final runVoiceCueClientProvider = Provider<RunVoiceCueClient>(
  (Ref ref) => FlutterTtsRunVoiceCueClient(),
);

final runVoiceCueSnapshotProvider = Provider<RunVoiceCueSnapshot>((Ref ref) {
  return RunVoiceCueSnapshot(
    playbackState: ref.watch(runPlaybackControllerProvider),
    metrics: ref.watch(liveRunMetricsProvider),
    intervalFrame: ref.watch(runIntervalFrameProvider),
    ghostFrame: ref.watch(ghostRaceFrameProvider),
    settings:
        ref.watch(runSettingsControllerProvider).value ??
        const RunSettingsState(),
    now: ref.watch(runPlaybackClockProvider)(),
  );
});

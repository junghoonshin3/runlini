import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/voice/run_voice_cue_client.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/state/run_live_metrics_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_record_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

final runVoiceCueClientProvider = Provider<RunVoiceCueClient>(
  (Ref ref) => FlutterTtsRunVoiceCueClient(),
);

final runVoiceCueSnapshotProvider = Provider<RunVoiceCueSnapshot>((Ref ref) {
  final recordRaceSettings = ref.watch(recordRaceSettingsProvider);
  final selectedRecordRaceSession = ref
      .watch(runMapStaticStateProvider)
      .value
      ?.selectedRecordRaceSession;
  return RunVoiceCueSnapshot(
    playbackState: ref.watch(runPlaybackControllerProvider),
    metrics: ref.watch(liveRunMetricsProvider),
    intervalFrame: ref.watch(runIntervalFrameProvider),
    recordRaceFrame: ref.watch(recordRaceFrameProvider),
    settings:
        ref.watch(runSettingsControllerProvider).value ??
        const RunSettingsState(),
    now: ref.watch(runPlaybackClockProvider)(),
    isRecordRaceRun:
        selectedRecordRaceSession != null ||
        (recordRaceSettings.enabled &&
            recordRaceSettings.selectedSessionId != null),
  );
});

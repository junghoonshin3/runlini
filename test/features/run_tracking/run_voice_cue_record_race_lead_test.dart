// 기록 레이스 추월과 역전 음성 안내 문구를 검증하는 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

void main() {
  test('speaks overtake with explicit recordRace gap context', () {
    final coordinator = RunVoiceCueCoordinator();
    final settings = const RunSettingsState(recordRaceVoiceCueEnabled: true);
    final startedAt = DateTime(2026, 5, 3);

    coordinator.cuesFor(
      _snapshot(
        recordRaceFrame: _recordRace(RecordRaceStatus.behind, gapMs: -30000),
        settings: settings,
        now: startedAt,
      ),
    );
    coordinator.cuesFor(
      _snapshot(
        recordRaceFrame: _recordRace(RecordRaceStatus.behind, gapMs: -30000),
        settings: settings,
        now: startedAt.add(const Duration(seconds: 15)),
      ),
    );
    coordinator.cuesFor(
      _snapshot(
        recordRaceFrame: _recordRace(RecordRaceStatus.ahead, gapMs: 30000),
        settings: settings,
        now: startedAt.add(const Duration(seconds: 16)),
      ),
    );

    final cues = coordinator.cuesFor(
      _snapshot(
        recordRaceFrame: _recordRace(RecordRaceStatus.ahead, gapMs: 30000),
        settings: settings,
        now: startedAt.add(const Duration(seconds: 31)),
      ),
    );

    expect(
      cues.map((cue) => cue.text),
      contains('기록 레이스를 추월했어요. 지금은 기록 레이스보다 30초 앞서고 있어요'),
    );
  });

  test('speaks lost lead with explicit recordRace gap context', () {
    final coordinator = RunVoiceCueCoordinator();
    final settings = const RunSettingsState(recordRaceVoiceCueEnabled: true);
    final startedAt = DateTime(2026, 5, 3);

    coordinator.cuesFor(
      _snapshot(
        recordRaceFrame: _recordRace(RecordRaceStatus.ahead, gapMs: 30000),
        settings: settings,
        now: startedAt,
      ),
    );
    coordinator.cuesFor(
      _snapshot(
        recordRaceFrame: _recordRace(RecordRaceStatus.ahead, gapMs: 30000),
        settings: settings,
        now: startedAt.add(const Duration(seconds: 15)),
      ),
    );
    coordinator.cuesFor(
      _snapshot(
        recordRaceFrame: _recordRace(RecordRaceStatus.behind, gapMs: -30000),
        settings: settings,
        now: startedAt.add(const Duration(seconds: 16)),
      ),
    );

    final cues = coordinator.cuesFor(
      _snapshot(
        recordRaceFrame: _recordRace(RecordRaceStatus.behind, gapMs: -30000),
        settings: settings,
        now: startedAt.add(const Duration(seconds: 31)),
      ),
    );

    expect(
      cues.map((cue) => cue.text),
      contains('기록 레이스에게 역전당했어요. 지금은 기록 레이스보다 30초 뒤처지고 있어요'),
    );
  });
}

RunVoiceCueSnapshot _snapshot({
  required RecordRaceFrame recordRaceFrame,
  required RunSettingsState settings,
  required DateTime now,
}) {
  return RunVoiceCueSnapshot(
    playbackState: _playback(),
    metrics: _metrics(),
    intervalFrame: null,
    recordRaceFrame: recordRaceFrame,
    settings: settings,
    now: now,
    isRecordRaceRun: true,
  );
}

RunPlaybackState _playback() {
  return RunPlaybackState(
    status: RunScreenStatus.running,
    currentPointIndex: 0,
    recordedPoints: const [],
    elapsedBeforePauseMs: 0,
    startedAt: DateTime(2026, 5, 3),
    resumedAt: DateTime(2026, 5, 3),
    activeSessionId: 'run-a',
  );
}

LiveRunMetrics _metrics() {
  return const LiveRunMetrics(
    distanceKm: 0.5,
    elapsedMs: 321000,
    averagePaceSecPerKm: 320,
    averageSpeedKmh: 11.2,
    caloriesKcal: 45,
    isPaused: false,
  );
}

RecordRaceFrame _recordRace(RecordRaceStatus status, {required int gapMs}) {
  return RecordRaceFrame(
    status: status,
    timeGapMs: gapMs,
    distanceGapM: 30,
    recordRaceMarkerPoint: const MapCoordinate(latitude: 37, longitude: 127),
    isOffRoute: status == RecordRaceStatus.offRoute,
    routeProgress: 0.5,
    distanceToFinishM: 600,
    distanceFromRouteM: status == RecordRaceStatus.offRoute ? 40 : 4,
    totalRouteDistanceM: 1000,
    distanceToFinishPointM: 600,
  );
}

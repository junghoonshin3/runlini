// 기록 레이스 음성 안내 우선순위 정책을 검증하는 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/record_race/types/record_race_frame.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/types/live_run_metrics.dart';
import 'package:runlini/features/run_tracking/types/run_playback_state.dart';
import 'package:runlini/features/run_tracking/types/run_screen_status.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';

void main() {
  test(
    'prioritizes recordRace events over kilometer summaries in one tick',
    () {
      final coordinator = RunVoiceCueCoordinator();
      final startedAt = DateTime(2026, 5, 3);
      final settings = const RunSettingsState(recordRaceVoiceCueEnabled: true);

      coordinator.cuesFor(
        _snapshot(
          isRecordRaceRun: true,
          metrics: _metrics(distanceKm: 0.5),
          recordRaceFrame: _recordRace(RecordRaceStatus.offRoute, gapMs: 0),
          settings: settings,
          now: startedAt,
        ),
      );
      final cues = coordinator.cuesFor(
        _snapshot(
          isRecordRaceRun: true,
          metrics: _metrics(distanceKm: 1.01),
          recordRaceFrame: _recordRace(RecordRaceStatus.offRoute, gapMs: 0),
          settings: settings,
          now: startedAt.add(const Duration(seconds: 10)),
        ),
      );

      expect(cues.single.text, '경로를 벗어났어요');
      expect(cues.single.priority, RunVoiceCuePriority.urgent);
      expect(cues.single.text, isNot(contains('1킬로미터')));
    },
  );

  test('does not speak recordRace completion before start is confirmed', () {
    final coordinator = RunVoiceCueCoordinator();
    final cues = coordinator.cuesFor(
      _snapshot(
        playbackState: _playback().copyWith(
          recordRaceCompletionPromptPending: true,
        ),
        isRecordRaceRun: true,
        metrics: _metrics(distanceKm: 0.5),
        recordRaceFrame: _recordRace(
          RecordRaceStatus.ahead,
          gapMs: 12000,
          startConfirmed: false,
          distanceToFinishM: 20,
        ),
        settings: const RunSettingsState(recordRaceVoiceCueEnabled: true),
      ),
    );

    expect(cues.map((cue) => cue.text), isNot(contains('기록 레이스 코스 완료')));
  });

  test('speaks recordRace completion using Wear wording', () {
    final aheadCoordinator = RunVoiceCueCoordinator();
    final aheadCues = aheadCoordinator.cuesFor(
      _snapshot(
        playbackState: _playback().copyWith(
          recordRaceCompletionPromptPending: true,
        ),
        isRecordRaceRun: true,
        metrics: _metrics(distanceKm: 1.01),
        recordRaceFrame: _recordRace(
          RecordRaceStatus.ahead,
          gapMs: 32000,
          distanceToFinishM: 20,
        ),
        settings: const RunSettingsState(recordRaceVoiceCueEnabled: true),
      ),
    );

    expect(aheadCues.single.text, '기록 레이스 코스 완료. 기록 레이스보다 32초 빨랐어요');
    expect(aheadCues.single.priority, RunVoiceCuePriority.urgent);
    expect(aheadCues.map((cue) => cue.text), isNot(contains('32초 앞서요')));

    final behindCoordinator = RunVoiceCueCoordinator();
    final behindCues = behindCoordinator.cuesFor(
      _snapshot(
        playbackState: _playback().copyWith(
          recordRaceCompletionPromptPending: true,
        ),
        isRecordRaceRun: true,
        metrics: _metrics(distanceKm: 0.5),
        recordRaceFrame: _recordRace(
          RecordRaceStatus.behind,
          gapMs: -47000,
          distanceToFinishM: 20,
        ),
        settings: const RunSettingsState(recordRaceVoiceCueEnabled: true),
      ),
    );

    expect(behindCues.single.text, '기록 레이스 코스 완료. 기록 레이스보다 47초 늦었어요');
    expect(behindCues.single.priority, RunVoiceCuePriority.urgent);
    expect(behindCues.map((cue) => cue.text), isNot(contains('47초 뒤처져요')));
  });
}

RunVoiceCueSnapshot _snapshot({
  RunPlaybackState? playbackState,
  LiveRunMetrics? metrics,
  RecordRaceFrame? recordRaceFrame,
  RunSettingsState settings = const RunSettingsState(),
  DateTime? now,
  bool isRecordRaceRun = false,
}) {
  return RunVoiceCueSnapshot(
    playbackState: playbackState ?? _playback(),
    metrics: metrics ?? _metrics(),
    intervalFrame: null,
    recordRaceFrame: recordRaceFrame,
    settings: settings,
    now: now ?? DateTime(2026, 5, 3),
    isRecordRaceRun: isRecordRaceRun,
  );
}

RunPlaybackState _playback({RunScreenStatus status = RunScreenStatus.running}) {
  return RunPlaybackState(
    status: status,
    currentPointIndex: 0,
    recordedPoints: const [],
    elapsedBeforePauseMs: 0,
    startedAt: DateTime(2026, 5, 3),
    resumedAt: DateTime(2026, 5, 3),
    activeSessionId: 'run-a',
  );
}

LiveRunMetrics _metrics({double distanceKm = 1.01}) {
  return LiveRunMetrics(
    distanceKm: distanceKm,
    elapsedMs: 321000,
    averagePaceSecPerKm: 320,
    averageSpeedKmh: 11.2,
    caloriesKcal: 45,
    isPaused: false,
  );
}

RecordRaceFrame _recordRace(
  RecordRaceStatus status, {
  required int gapMs,
  bool startConfirmed = true,
  double distanceToFinishM = 600,
}) {
  return RecordRaceFrame(
    status: status,
    timeGapMs: gapMs,
    distanceGapM: 30,
    recordRaceMarkerPoint: const MapCoordinate(latitude: 37, longitude: 127),
    isOffRoute: status == RecordRaceStatus.offRoute,
    routeProgress: 0.5,
    distanceToFinishM: distanceToFinishM,
    distanceFromRouteM: status == RecordRaceStatus.offRoute ? 40 : 4,
    totalRouteDistanceM: 1000,
    distanceToFinishPointM: distanceToFinishM,
    startConfirmed: startConfirmed,
  );
}

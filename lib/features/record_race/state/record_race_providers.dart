import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/record_race/types/record_race_settings_state.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

class RecordRaceSettingsNotifier extends Notifier<RecordRaceSettingsState> {
  @override
  RecordRaceSettingsState build() => const RecordRaceSettingsState.disabled();

  void selectSession(RunSessionSummary summary) {
    state = RecordRaceSettingsState(
      enabled: true,
      selectedSessionId: summary.id,
      selectedSessionSummary: summary,
    );
    unawaited(_syncRecentRecordRaceConfigs(selectedSessionId: summary.id));
  }

  void disable() {
    state = const RecordRaceSettingsState.disabled();
    unawaited(_syncRecentRecordRaceConfigs());
  }

  Future<void> _syncRecentRecordRaceConfigs({String? selectedSessionId}) async {
    try {
      final sessions = await ref.read(
        recentWatchRecordRaceSessionsProvider(selectedSessionId).future,
      );
      await ref
          .read(watchRecordRaceConfigSyncServiceProvider)
          .syncRecentSessions(sessions, selectedSessionId: selectedSessionId);
    } catch (_) {
      // RecordRace selection should not block the phone run UI.
    }
  }
}

final recordRaceSettingsProvider =
    NotifierProvider<RecordRaceSettingsNotifier, RecordRaceSettingsState>(
      RecordRaceSettingsNotifier.new,
    );

final selectedRecordRaceSessionProvider = FutureProvider<RunSession?>((
  Ref ref,
) async {
  final settings = ref.watch(recordRaceSettingsProvider);
  if (!settings.enabled || settings.selectedSessionId == null) {
    return null;
  }

  return ref.watch(runSessionByIdProvider(settings.selectedSessionId!).future);
});

final selectedRecordRacePolylinePointsProvider =
    FutureProvider<List<MapCoordinate>>((Ref ref) async {
      final selectedSession = await ref.watch(
        selectedRecordRaceSessionProvider.future,
      );
      if (selectedSession == null) {
        return const <MapCoordinate>[];
      }

      return mapCoordinatesFromRunPoints(selectedSession.points);
    });

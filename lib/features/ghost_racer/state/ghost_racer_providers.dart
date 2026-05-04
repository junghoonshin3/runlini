import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_settings_state.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

class GhostSettingsNotifier extends Notifier<GhostSettingsState> {
  @override
  GhostSettingsState build() => const GhostSettingsState.disabled();

  void selectSession(RunSessionSummary summary) {
    state = GhostSettingsState(
      enabled: true,
      selectedSessionId: summary.id,
      selectedSessionSummary: summary,
    );
    unawaited(_syncRecentGhostConfigs(selectedSessionId: summary.id));
  }

  void disable() {
    state = const GhostSettingsState.disabled();
    unawaited(_syncRecentGhostConfigs());
  }

  Future<void> _syncRecentGhostConfigs({String? selectedSessionId}) async {
    try {
      final sessions = await ref.read(
        recentWatchGhostSessionsProvider(selectedSessionId).future,
      );
      await ref
          .read(watchGhostConfigSyncServiceProvider)
          .syncRecentSessions(sessions, selectedSessionId: selectedSessionId);
    } catch (_) {
      // Ghost selection should not block the phone run UI.
    }
  }
}

final ghostSettingsProvider =
    NotifierProvider<GhostSettingsNotifier, GhostSettingsState>(
      GhostSettingsNotifier.new,
    );

final selectedGhostSessionProvider = FutureProvider<RunSession?>((
  Ref ref,
) async {
  final settings = ref.watch(ghostSettingsProvider);
  if (!settings.enabled || settings.selectedSessionId == null) {
    return null;
  }

  return ref.watch(runSessionByIdProvider(settings.selectedSessionId!).future);
});

final selectedGhostPolylinePointsProvider = FutureProvider<List<MapCoordinate>>(
  (Ref ref) async {
    final selectedSession = await ref.watch(
      selectedGhostSessionProvider.future,
    );
    if (selectedSession == null) {
      return const <MapCoordinate>[];
    }

    return mapCoordinatesFromRunPoints(selectedSession.points);
  },
);

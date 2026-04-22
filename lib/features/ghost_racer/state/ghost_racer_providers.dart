import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/types/ghost_settings_state.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
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
  }

  void disable() {
    state = const GhostSettingsState.disabled();
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

  final sessions = await ref.watch(runSessionListProvider.future);
  for (final session in sessions) {
    if (session.id == settings.selectedSessionId) {
      return session;
    }
  }

  return null;
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

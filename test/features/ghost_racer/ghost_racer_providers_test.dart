import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/ghost_racer/state/ghost_racer_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

void main() {
  test('builds ghost polyline points from the selected session id', () async {
    final session = RunSession(
      id: 'ghost-selected',
      startedAt: DateTime.utc(2026, 4, 19, 6, 30),
      endedAt: DateTime.utc(2026, 4, 19, 6, 42),
      distanceM: 2400,
      durationMs: 720000,
      sourceSummary: 'fixture:test',
      points: const [
        RunPoint(
          latitude: 37.0,
          longitude: 127.0,
          timestampRelMs: 0,
          paceSecPerKm: 300,
          source: RunPointSource.simulated,
        ),
        RunPoint(
          latitude: 37.0002,
          longitude: 127.0002,
          timestampRelMs: 1000,
          paceSecPerKm: 300,
          source: RunPointSource.simulated,
        ),
      ],
    );
    final summary = RunSessionSummary.fromSession(session);
    final container = ProviderContainer(
      overrides: [
        runSessionListProvider.overrideWith((Ref ref) async => [session]),
      ],
    );
    addTearDown(container.dispose);

    container.read(ghostSettingsProvider.notifier).selectSession(summary);
    final polylinePoints = await container.read(
      selectedGhostPolylinePointsProvider.future,
    );

    expect(polylinePoints, hasLength(2));
    expect(
      polylinePoints.first,
      const MapCoordinate(latitude: 37.0, longitude: 127.0),
    );
  });
}

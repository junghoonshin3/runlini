// 러닝 탭의 오늘 기록 레이스 추천 카드 흐름을 검증한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('shows a recommendation and selects it as record race', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 5, 18, 7);
    final sessions = <RunSession>[
      _session(id: 'latest-other-day', startedAt: DateTime(2026, 5, 17, 7)),
      _session(id: 'same-weekday', startedAt: DateTime(2026, 5, 11, 7)),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          staticMapStateOverride(
            fallbackMapCenter: const MapCoordinate(
              latitude: 37.0,
              longitude: 127.0,
            ),
          ),
          deviceLocationClientProvider.overrideWithValue(
            FakeDeviceLocationClient(
              lastKnownSample: sample(latitude: 37.55, longitude: 126.97),
            ),
          ),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(sessions),
          ),
          runPlaybackClockProvider.overrideWithValue(() => now),
        ],
        child: const RunliniApp(),
      ),
    );
    await tester.pump();
    await openRunningTab(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('record-race-recommendation-card')),
    );

    expect(find.text('오늘 추천'), findsOneWidget);
    expect(find.text('같은 요일 기록으로 달리기'), findsOneWidget);
    expect(find.byKey(const Key('record-race-control-chip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('record-race-recommendation-card')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('record-race-recommendation-card')),
      findsNothing,
    );
    expect(find.text('기록 레이스 ON'), findsOneWidget);
  });
}

RunSession _session({required String id, required DateTime startedAt}) {
  return RunSession(
    id: id,
    startedAt: startedAt,
    distanceM: 3000,
    durationMs: 1080000,
    sourceSummary: 'device:gps',
    points: const [
      RunPoint(
        latitude: 37.5,
        longitude: 127.0,
        timestampRelMs: 0,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.51,
        longitude: 127.01,
        timestampRelMs: 1080000,
        source: RunPointSource.simulated,
      ),
    ],
  );
}

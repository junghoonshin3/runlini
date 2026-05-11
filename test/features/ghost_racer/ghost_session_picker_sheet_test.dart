// 고스트 기록 선택 바텀시트의 확장 선택 흐름을 검증한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/ghost_racer/ui/ghost_session_picker_sheet.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('opens with the latest session expanded', (
    WidgetTester tester,
  ) async {
    final sessions = sampleRunSessions();

    await _pumpSheet(tester, sessions);

    expect(
      find.byKey(const Key('ghost-session-select-fixture_morning_tempo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ghost-session-select-fixture_han_river_push')),
      findsNothing,
    );
    expect(find.byKey(const Key('ghost-route-shape-layer')), findsOneWidget);
  });

  testWidgets('tapping a compact session expands it before selection', (
    WidgetTester tester,
  ) async {
    final sessions = sampleRunSessions();

    await _pumpSheet(tester, sessions);
    await tester.ensureVisible(
      find.byKey(const Key('ghost-session-item-fixture_han_river_push')),
    );
    await tester.tap(
      find.byKey(const Key('ghost-session-item-fixture_han_river_push')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('ghost-session-select-fixture_han_river_push')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ghost-session-select-fixture_morning_tempo')),
      findsNothing,
    );
  });

  testWidgets('shows route fallback when expanded session has too few points', (
    WidgetTester tester,
  ) async {
    final session = _singlePointSession();

    await _pumpSheet(tester, [session]);

    expect(find.byKey(const Key('ghost-route-shape-fallback')), findsOneWidget);
    expect(find.text('경로 데이터가 부족해요.'), findsOneWidget);
  });
}

Future<void> _pumpSheet(WidgetTester tester, List<RunSession> sessions) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(sessions),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: GhostSessionPickerSheet(
            summaries: sessions
                .map(RunSessionSummary.fromSession)
                .toList(growable: false),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RunSession _singlePointSession() {
  return RunSession(
    id: 'single-point-run',
    startedAt: DateTime(2026, 5, 9, 6),
    distanceM: 1000,
    durationMs: 360000,
    sourceSummary: 'device:gps',
    points: const <RunPoint>[
      RunPoint(
        latitude: 37.5,
        longitude: 127,
        timestampRelMs: 0,
        source: RunPointSource.deviceGps,
      ),
    ],
  );
}

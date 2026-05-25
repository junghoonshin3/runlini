// 기록 레이스 기록 선택 바텀시트의 확장 선택 흐름을 검증한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/record_race/ui/record_race_route_shape_preview.dart';
import 'package:runlini/features/record_race/ui/record_race_session_picker_sheet.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('route preview loading renders a local skeleton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecordRaceRouteShapePreview(points: null, isLoading: true),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('record-race-route-shape-loading')),
      findsOneWidget,
    );
    expect(find.text('경로를 불러오는 중'), findsNothing);
  });

  testWidgets('opens with the recommended session expanded', (
    WidgetTester tester,
  ) async {
    final sessions = sampleRunSessions();
    final recommended = RunSessionSummary.fromSession(sessions.last);

    await _pumpSheet(
      tester,
      sessions,
      recommendedSummary: recommended,
      recommendationReason: '같은 요일 기록으로 달리기',
    );

    expect(
      find.byKey(const Key('record-race-session-recommendation-card')),
      findsOneWidget,
    );
    expect(find.text('오늘 추천'), findsOneWidget);
    expect(find.text('같은 요일 기록으로 달리기'), findsOneWidget);
    expect(
      find.byKey(
        const Key('record-race-session-select-fixture_han_river_push'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('record-race-session-select-fixture_morning_tempo')),
      findsNothing,
    );
  });

  testWidgets('opens with the latest session expanded', (
    WidgetTester tester,
  ) async {
    final sessions = sampleRunSessions();

    await _pumpSheet(tester, sessions);

    expect(
      find.byKey(const Key('record-race-session-select-fixture_morning_tempo')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('record-race-session-select-fixture_han_river_push'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const Key('record-race-route-shape-layer')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a compact session expands it before selection', (
    WidgetTester tester,
  ) async {
    final sessions = sampleRunSessions();

    await _pumpSheet(tester, sessions);
    await tester.ensureVisible(
      find.byKey(const Key('record-race-session-item-fixture_han_river_push')),
    );
    await tester.tap(
      find.byKey(const Key('record-race-session-item-fixture_han_river_push')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const Key('record-race-session-select-fixture_han_river_push'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('record-race-session-select-fixture_morning_tempo')),
      findsNothing,
    );
  });

  testWidgets('hides sessions with too few points from selection', (
    WidgetTester tester,
  ) async {
    final session = _singlePointSession();

    await _pumpSheet(tester, [session]);

    expect(
      find.byKey(const Key('record-race-session-empty-state')),
      findsOneWidget,
    );
    expect(find.text('경로가 있는 러닝 기록을 저장하면 경쟁레이스를 시작할 수 있어요.'), findsOneWidget);
    expect(
      find.byKey(const Key('record-race-session-select-single-point-run')),
      findsNothing,
    );
  });
}

Future<void> _pumpSheet(
  WidgetTester tester,
  List<RunSession> sessions, {
  RunSessionSummary? recommendedSummary,
  String? recommendationReason,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(sessions),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: RecordRaceSessionPickerSheet(
            summaries: sessions
                .map(RunSessionSummary.fromSession)
                .toList(growable: false),
            recommendedSummary: recommendedSummary,
            recommendationReason: recommendationReason,
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

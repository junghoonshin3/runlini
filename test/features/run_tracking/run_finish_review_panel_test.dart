import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_ghost_summary.dart';
import 'package:runlini/features/run_tracking/ui/run_finish_review_panel.dart';

void main() {
  testWidgets('hides ghost comparison for a normal run', (tester) async {
    await _pumpPanel(tester, _session());

    expect(find.byKey(const Key('detail-ghost-compare')), findsNothing);
    expect(find.byKey(const Key('detail-chart-pace')), findsOneWidget);
  });

  testWidgets('shows ghost comparison for a ghost-enabled run', (tester) async {
    await _pumpPanel(
      tester,
      _session(
        ghostSummary: const RunSessionGhostSummary(
          result: RunSessionGhostResult.ahead,
          timeGapMs: 12000,
          distanceGapM: 42,
          ghostSessionId: 'ghost-a',
          ghostLabel: 'Morning Ghost',
        ),
      ),
    );

    expect(find.byKey(const Key('detail-ghost-compare')), findsOneWidget);
    expect(find.text('Ghost Compare'), findsOneWidget);
    expect(find.text('You beat the ghost'), findsOneWidget);
  });
}

Future<void> _pumpPanel(WidgetTester tester, RunSession session) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: RunFinishReviewPanel(session: session)),
    ),
  );
  await tester.pump();
}

RunSession _session({RunSessionGhostSummary? ghostSummary}) {
  return RunSession(
    id: 'panel-session',
    startedAt: DateTime.utc(2026, 4, 21, 6),
    endedAt: DateTime.utc(2026, 4, 21, 6, 10),
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'fixture:test',
    ghostSummary: ghostSummary,
    points: const [
      RunPoint(
        latitude: 37.0,
        longitude: 127.0,
        timestampRelMs: 0,
        paceSecPerKm: 420,
        source: RunPointSource.simulated,
      ),
      RunPoint(
        latitude: 37.001,
        longitude: 127.001,
        timestampRelMs: 600000,
        paceSecPerKm: 410,
        source: RunPointSource.simulated,
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/history/history_distance_progress_panel.dart';

void main() {
  testWidgets('shows week total and switches to month and year totals', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _Host(
        child: HistoryDistanceProgressPanel(
          sessions: [
            _session('last-month', DateTime(2026, 3, 30), 1000),
            _session('this-week', DateTime(2026, 4, 27), 3000),
            _session('this-month', DateTime(2026, 4, 10), 2000),
          ],
          displaySettings: const RunDisplaySettings(),
          distanceGoals: const RunDistanceGoalSettings(
            weeklyGoalM: 6000,
            monthlyGoalM: 10000,
            yearlyGoalM: 12000,
          ),
          now: DateTime(2026, 4, 28, 12),
        ),
      ),
    );

    expect(find.byKey(const Key('history-distance-progress-panel')), findsOne);
    expect(find.byKey(const Key('history-distance-progress-ring')), findsOne);
    expect(find.text('이번주 달린 거리'), findsOne);
    expect(find.text('3.00 km'), findsOne);

    await tester.tap(find.byKey(const Key('history-period-month-button')));
    await tester.pumpAndSettle();

    expect(find.text('이번달 달린 거리'), findsOne);
    expect(find.text('5.00 km'), findsOne);

    await tester.tap(find.byKey(const Key('history-period-year-button')));
    await tester.pumpAndSettle();

    expect(find.text('올해 달린 거리'), findsOne);
    expect(find.text('6.00 km'), findsOne);
  });

  testWidgets('uses display unit settings for distance labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _Host(
        child: HistoryDistanceProgressPanel(
          sessions: [_session('this-week', DateTime(2026, 4, 27), 3000)],
          displaySettings: const RunDisplaySettings(
            distanceUnit: RunDistanceUnit.mi,
            paceUnit: RunPaceUnit.minPerMi,
            speedUnit: RunSpeedUnit.mph,
          ),
          distanceGoals: const RunDistanceGoalSettings(),
          now: DateTime(2026, 4, 28, 12),
        ),
      ),
    );

    expect(find.text('1.86 mi'), findsOne);
  });

  testWidgets('runs the change-goals callback', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _Host(
        child: HistoryDistanceProgressPanel(
          sessions: [_session('this-week', DateTime(2026, 4, 27), 3000)],
          displaySettings: const RunDisplaySettings(),
          distanceGoals: const RunDistanceGoalSettings(),
          onChangeGoals: () => tapped = true,
          now: DateTime(2026, 4, 28, 12),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('history-change-goals-button')));

    expect(tapped, isTrue);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}

RunSessionSummary _session(String id, DateTime startedAt, double distanceM) {
  return RunSessionSummary.fromSession(
    RunSession(
      id: id,
      startedAt: startedAt,
      distanceM: distanceM,
      durationMs: 600000,
      sourceSummary: 'test',
      points: const [],
    ),
  );
}

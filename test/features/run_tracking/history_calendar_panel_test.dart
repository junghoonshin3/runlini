import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/history/history_calendar_panel.dart';

void main() {
  testWidgets('defaults to a weekly calendar and expands to month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _Host(
        child: HistoryCalendarPanel(
          sessions: [
            _session('week-run', DateTime(2026, 4, 28), 3000),
            _session('month-run', DateTime(2026, 4, 10), 5000),
          ],
          displaySettings: const RunDisplaySettings(),
          distanceGoals: const RunDistanceGoalSettings(monthlyGoalM: 90000),
          now: DateTime(2026, 4, 28, 12),
        ),
      ),
    );

    expect(find.byKey(const Key('history-calendar-panel')), findsOneWidget);
    expect(find.byKey(const Key('history-calendar-toggle-button')), findsOne);
    expect(find.byKey(const Key('history-calendar-week-button')), findsOne);
    expect(find.byKey(const Key('history-calendar-month-button')), findsOne);
    expect(find.byKey(const Key('history-calendar-day-2026-04-28')), findsOne);
    expect(
      find.byKey(const Key('history-calendar-day-2026-04-10')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('history-calendar-month-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-calendar-day-2026-04-10')), findsOne);
    expect(find.text('월간'), findsOne);

    await tester.tap(find.byKey(const Key('history-calendar-week-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('history-calendar-day-2026-04-10')),
      findsNothing,
    );
  });

  testWidgets('selects a day and shows today action away from today', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _Host(
        child: _SelectableCalendar(
          sessions: [_session('run', DateTime(2026, 4, 27), 3000)],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('history-calendar-day-2026-04-27')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('history-calendar-clear-selection-button')),
      findsOne,
    );
    expect(find.text('오늘 보기'), findsOne);

    await tester.tap(
      find.byKey(const Key('history-calendar-clear-selection-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('history-calendar-clear-selection-button')),
      findsNothing,
    );
  });

  testWidgets('swipes weekly calendar by one week', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _Host(
        child: HistoryCalendarPanel(
          sessions: const [],
          displaySettings: const RunDisplaySettings(),
          distanceGoals: const RunDistanceGoalSettings(),
          now: DateTime(2026, 4, 28, 12),
        ),
      ),
    );

    expect(find.byKey(const Key('history-calendar-day-2026-04-28')), findsOne);

    await tester.drag(
      find.byKey(const Key('history-calendar-swipe-area')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-calendar-day-2026-05-04')), findsOne);
    expect(
      find.byKey(const Key('history-calendar-day-2026-04-28')),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const Key('history-calendar-swipe-area')),
      const Offset(300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-calendar-day-2026-04-28')), findsOne);
  });

  testWidgets('swipes monthly calendar by one month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _Host(
        child: HistoryCalendarPanel(
          sessions: const [],
          displaySettings: const RunDisplaySettings(),
          distanceGoals: const RunDistanceGoalSettings(),
          now: DateTime(2026, 4, 28, 12),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('history-calendar-month-button')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('history-calendar-swipe-area')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026년 5월'), findsOne);
    expect(find.byKey(const Key('history-calendar-day-2026-05-31')), findsOne);

    await tester.drag(
      find.byKey(const Key('history-calendar-swipe-area')),
      const Offset(300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026년 4월'), findsOne);
    expect(find.byKey(const Key('history-calendar-day-2026-04-30')), findsOne);
  });

  testWidgets('monthly calendar does not overflow on a narrow screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _Host(
        child: HistoryCalendarPanel(
          sessions: [
            _session('multi-1', DateTime(2026, 4, 14), 14000),
            _session('multi-2', DateTime(2026, 4, 14, 18), 500),
            _session('today', DateTime(2026, 4, 28), 900),
          ],
          displaySettings: const RunDisplaySettings(),
          distanceGoals: const RunDistanceGoalSettings(monthlyGoalM: 150000),
          selectedDate: DateTime(2026, 4, 28),
          now: DateTime(2026, 4, 28, 12),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('history-calendar-month-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-calendar-day-2026-04-30')), findsOne);

    await tester.drag(
      find.byKey(const Key('history-calendar-swipe-area')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026년 5월'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('run count badge stays away from the day number', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _Host(
        child: HistoryCalendarPanel(
          sessions: [
            for (var index = 0; index < 14; index += 1)
              _session('run-$index', DateTime(2026, 4, 21, index), 250),
          ],
          displaySettings: const RunDisplaySettings(),
          distanceGoals: const RunDistanceGoalSettings(monthlyGoalM: 150000),
          now: DateTime(2026, 4, 21, 12),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('history-calendar-month-button')));
    await tester.pumpAndSettle();

    final dayRect = tester.getRect(find.text('21'));
    final badgeRect = tester.getRect(
      find.byKey(const Key('history-calendar-run-count-2026-04-21')),
    );

    expect(badgeRect.center.dx, greaterThan(dayRect.center.dx));
    expect(badgeRect.center.dy, lessThan(dayRect.center.dy));
    expect(tester.takeException(), isNull);
  });
}

class _SelectableCalendar extends StatefulWidget {
  const _SelectableCalendar({required this.sessions});

  final List<RunSession> sessions;

  @override
  State<_SelectableCalendar> createState() => _SelectableCalendarState();
}

class _SelectableCalendarState extends State<_SelectableCalendar> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return HistoryCalendarPanel(
      sessions: widget.sessions,
      displaySettings: const RunDisplaySettings(),
      distanceGoals: const RunDistanceGoalSettings(),
      selectedDate: _selectedDate,
      onSelectedDate: (DateTime date) => setState(() => _selectedDate = date),
      onClearSelectedDate: () => setState(() => _selectedDate = null),
      now: DateTime(2026, 4, 28, 12),
    );
  }
}

class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}

RunSession _session(String id, DateTime startedAt, double distanceM) {
  return RunSession(
    id: id,
    startedAt: startedAt,
    distanceM: distanceM,
    durationMs: 600000,
    sourceSummary: 'test',
    points: const [],
  );
}

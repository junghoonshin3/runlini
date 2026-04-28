import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/ui/history/history_tab_screen.dart';

void main() {
  testWidgets('opens history on today and returns date selection to today', (
    WidgetTester tester,
  ) async {
    final today = DateTime(2026, 4, 28, 12);
    final todaySession = _session('today-run', DateTime(2026, 4, 28, 7));
    final yesterdaySession = _session(
      'yesterday-run',
      DateTime(2026, 4, 27, 7),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionListProvider.overrideWith(
            (Ref ref) async => [todaySession, yesterdaySession],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: HistoryTabScreen(now: today)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('최근 기록'), findsNothing);
    expect(find.text('4월 28일 기록'), findsOneWidget);
    expect(find.byKey(const Key('history-session-today-run')), findsOneWidget);
    expect(
      find.byKey(const Key('history-session-yesterday-run')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('history-calendar-clear-selection-button')),
      findsNothing,
    );

    final yesterdayCell = find.byKey(
      const Key('history-calendar-day-2026-04-27'),
    );
    await tester.ensureVisible(yesterdayCell);
    await tester.pumpAndSettle();
    await tester.tap(yesterdayCell);
    await tester.pumpAndSettle();

    expect(find.text('4월 27일 기록'), findsOneWidget);
    expect(find.byKey(const Key('history-session-today-run')), findsNothing);
    expect(
      find.byKey(const Key('history-session-yesterday-run')),
      findsOneWidget,
    );
    expect(find.text('오늘 보기'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('history-calendar-clear-selection-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('4월 28일 기록'), findsOneWidget);
    expect(find.byKey(const Key('history-session-today-run')), findsOneWidget);
    expect(
      find.byKey(const Key('history-session-yesterday-run')),
      findsNothing,
    );
  });
}

RunSession _session(String id, DateTime startedAt) {
  return RunSession(
    id: id,
    startedAt: startedAt,
    distanceM: 1000,
    durationMs: 600000,
    sourceSummary: 'test',
    points: const [],
  );
}

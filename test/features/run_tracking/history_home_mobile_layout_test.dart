// 홈 기록 화면의 모바일 레이아웃 회귀를 검증하는 위젯 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/history/history_calendar_panel.dart';
import 'package:runlini/features/run_tracking/ui/history/history_tab_screen.dart';

void main() {
  testWidgets('keeps home history sections visible on a mobile viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final today = DateTime(2026, 4, 28, 12);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionSummaryListProvider.overrideWith(
            (Ref ref) async => [
              RunSessionSummary.fromSession(
                _session('today-run', DateTime(2026, 4, 28, 7), 1000),
              ),
              RunSessionSummary.fromSession(
                _session('yesterday-run', DateTime(2026, 4, 27, 7), 1000),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(body: HistoryTabScreen(now: today)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('history-distance-progress-panel')), findsOne);
    final todaySummaryBadge = find.byKey(
      const Key('history-today-summary-badge'),
    );
    expect(todaySummaryBadge, findsOne);
    expect(
      find.descendant(of: todaySummaryBadge, matching: find.text('1.0 km')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: todaySummaryBadge, matching: find.text('1회')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('history-calendar-panel')), findsOne);
    expect(find.byKey(const Key('history-session-today-run')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('history-session-today-run'))).dy,
      lessThan(844),
    );
    expect(
      tester.widget<Text>(find.text('오늘 기록과 목표를 바로 확인합니다.')).maxLines,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps calendar view controls large enough on mobile', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _CalendarHost(
        child: HistoryCalendarPanel(
          sessions: const [],
          displaySettings: const RunDisplaySettings(),
          distanceGoals: const RunDistanceGoalSettings(),
          now: DateTime(2026, 4, 28, 12),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const Key('history-calendar-week-button')))
          .height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('history-calendar-month-button')))
          .height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.takeException(), isNull);
  });
}

class _CalendarHost extends StatelessWidget {
  const _CalendarHost({required this.child});

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

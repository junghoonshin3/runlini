import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_interval_providers.dart';
import 'package:runlini/features/run_tracking/state/run_record_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/types/run_session_summary.dart';
import 'package:runlini/features/run_tracking/ui/running/run_record_race_control_chip.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('recordRace chip shows compact skeleton while summaries load', (
    WidgetTester tester,
  ) async {
    final pending = Completer<List<RunSessionSummary>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionSummaryListProvider.overrideWith((ref) => pending.future),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RunRecordRaceControlChip()),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('record-race-control-chip-skeleton')),
      findsOneWidget,
    );
    expect(find.text('경쟁레이스 선택'), findsNothing);
  });

  testWidgets(
    'selects changes and clears a recordRace session from the selector',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disableStartupWeightPromptOverride,
            runSessionRepositoryProvider.overrideWithValue(
              FakeRunSessionRepository(sampleRunSessions()),
            ),
            runRecordRaceRecommendationProvider.overrideWith(
              (ref) async => null,
            ),
            locationStreamClientProvider.overrideWithValue(
              const SilentLocationStreamClient(),
            ),
          ],
          child: const RunliniApp(),
        ),
      );
      await tester.pump();
      await openRunningTab(tester);
      await pumpUntilFound(
        tester,
        find.byKey(const Key('record-race-fallback-card')),
      );
      expect(find.byKey(const Key('settings-button')), findsNothing);
      expect(find.byKey(const Key('run-interval-button')), findsOneWidget);
      await _openRecordRacePickerFromTopCard(tester);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('record-race-session-draggable-sheet')),
        findsOneWidget,
      );
      final handleFinder = find.byKey(
        const Key('record-race-session-drag-handle'),
      );
      expect(tester.getTopLeft(handleFinder).dy, lessThan(40));
      expect(
        find.byKey(const Key('record-race-route-shape-preview')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(
          const Key('record-race-session-select-fixture_morning_tempo'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('record-race-session-select-fixture_morning_tempo'),
        ),
      );
      await pumpUntilFound(tester, find.textContaining('경쟁레이스 ·'));
      await pumpUntilFound(
        tester,
        find.byKey(const Key('record-race-polyline-layer')),
      );

      expect(
        find.byKey(const Key('record-race-polyline-layer')),
        findsOneWidget,
      );
      expect(find.textContaining('경쟁레이스 ·'), findsOneWidget);
      expect(
        find.byKey(const Key('record-race-selected-clear-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('record-race-selected-change-button')),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const Key('record-race-session-sheet')),
      );
      expect(
        find.byKey(const Key('record-race-polyline-layer')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(
          const Key('record-race-session-select-fixture_morning_tempo'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('record-race-session-select-fixture_morning_tempo'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('record-race-selected-clear-button')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('record-race-polyline-layer')), findsNothing);
      expect(find.text('내 기록과 다시 달리기'), findsOneWidget);
    },
  );

  testWidgets(
    'recordRace session picker opens full and closes when pulled down',
    (WidgetTester tester) async {
      tester.view.padding = const FakeViewPadding(top: 84);
      tester.view.viewPadding = const FakeViewPadding(top: 84);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            disableStartupWeightPromptOverride,
            runSessionRepositoryProvider.overrideWithValue(
              FakeRunSessionRepository(sampleRunSessions()),
            ),
            runRecordRaceRecommendationProvider.overrideWith(
              (ref) async => null,
            ),
            locationStreamClientProvider.overrideWithValue(
              const SilentLocationStreamClient(),
            ),
          ],
          child: const RunliniApp(),
        ),
      );
      await tester.pump();
      await openRunningTab(tester);
      await _openRecordRacePickerFromTopCard(tester);
      await tester.pumpAndSettle();

      final handleFinder = find.byKey(
        const Key('record-race-session-drag-handle'),
      );
      expect(tester.getTopLeft(handleFinder).dy, greaterThanOrEqualTo(28));

      await tester.drag(handleFinder, const Offset(0, 720));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('record-race-session-sheet')), findsNothing);
    },
  );

  testWidgets('short pull down snaps recordRace picker back to full height', (
    WidgetTester tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 84);
    tester.view.viewPadding = const FakeViewPadding(top: 84);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(sampleRunSessions()),
          ),
          runRecordRaceRecommendationProvider.overrideWith((ref) async => null),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await tester.pump();
    await openRunningTab(tester);
    await _openRecordRacePickerFromTopCard(tester);
    await tester.pumpAndSettle();

    final handleFinder = find.byKey(
      const Key('record-race-session-drag-handle'),
    );
    final initialTop = tester.getTopLeft(handleFinder).dy;

    await tester.drag(handleFinder, const Offset(0, 80));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('record-race-session-sheet')), findsOneWidget);
    expect(tester.getTopLeft(handleFinder).dy, initialTop);
  });

  testWidgets('hides the selector when there are no records', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(),
          ),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await tester.pump();
    await openRunningTab(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-button')), findsNothing);
    expect(find.byKey(const Key('run-interval-button')), findsOneWidget);
    expect(find.byKey(const Key('record-race-control-chip')), findsNothing);
    expect(
      find.byKey(const Key('record-race-recommendation-empty-card')),
      findsOneWidget,
    );
    expect(find.text('저장된 기록이 필요해요'), findsOneWidget);
    expect(find.byKey(const Key('record-race-session-sheet')), findsNothing);
  });

  testWidgets('running tab locked interval action shows future message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionRepositoryProvider.overrideWithValue(
            FakeRunSessionRepository(sampleRunSessions()),
          ),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await tester.pump();
    await openRunningTab(tester);
    await pumpUntilFound(tester, find.byKey(const Key('run-interval-button')));

    expect(find.byKey(const Key('settings-button')), findsNothing);

    await tester.tap(find.byKey(const Key('run-interval-button')));
    await tester.pumpAndSettle();

    expect(find.text(runIntervalFeatureLockedMessage), findsOneWidget);
    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsNothing);
    expect(find.byKey(const Key('record-race-toggle')), findsNothing);
  });
}

Future<void> _openRecordRacePickerFromTopCard(WidgetTester tester) async {
  await pumpUntilFound(
    tester,
    find.byKey(const Key('record-race-fallback-select-button')),
  );
  await tester.tap(find.byKey(const Key('record-race-fallback-select-button')));
  await pumpUntilFound(
    tester,
    find.byKey(const Key('record-race-session-sheet')),
  );
}

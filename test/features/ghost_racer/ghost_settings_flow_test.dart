import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/ui/history/run_session_summary_tile.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('selects and clears a ghost session from the running tab chip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionListProvider.overrideWith(
            (Ref ref) async => sampleRunSessions(),
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
    await pumpUntilFound(tester, find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.text('Ghost Run Off'));

    expect(find.byKey(const Key('settings-button')), findsNothing);
    expect(find.byKey(const Key('run-interval-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-session-sheet')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('ghost-session-draggable-sheet')),
      findsOneWidget,
    );
    final handleFinder = find.byKey(const Key('ghost-session-drag-handle'));
    expect(tester.getTopLeft(handleFinder).dy, lessThan(40));

    tester
        .widget<RunSessionSummaryTile>(
          find.byKey(const Key('ghost-session-item-fixture_han_river_push')),
        )
        .onTap!();
    await pumpUntilFound(tester, find.text('Ghost Run On'));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-polyline-layer')));

    expect(find.byKey(const Key('ghost-polyline-layer')), findsOneWidget);
    expect(find.text('Ghost Run On'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('ghost-polyline-layer')), findsNothing);
    expect(find.text('Ghost Run Off'), findsOneWidget);
  });

  testWidgets('ghost session picker opens full and closes when pulled down', (
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
          runSessionListProvider.overrideWith(
            (Ref ref) async => sampleRunSessions(),
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
    await pumpUntilFound(tester, find.byKey(const Key('ghost-control-chip')));

    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-session-sheet')));
    await tester.pumpAndSettle();

    final handleFinder = find.byKey(const Key('ghost-session-drag-handle'));
    expect(tester.getTopLeft(handleFinder).dy, greaterThanOrEqualTo(28));

    await tester.drag(handleFinder, const Offset(0, 720));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ghost-session-sheet')), findsNothing);
  });

  testWidgets('short pull down snaps ghost picker back to full height', (
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
          runSessionListProvider.overrideWith(
            (Ref ref) async => sampleRunSessions(),
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
    await pumpUntilFound(tester, find.byKey(const Key('ghost-control-chip')));

    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-session-sheet')));
    await tester.pumpAndSettle();

    final handleFinder = find.byKey(const Key('ghost-session-drag-handle'));
    final initialTop = tester.getTopLeft(handleFinder).dy;

    await tester.drag(handleFinder, const Offset(0, 80));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ghost-session-sheet')), findsOneWidget);
    expect(tester.getTopLeft(handleFinder).dy, initialTop);
  });

  testWidgets('shows a disabled chip when there are no records', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionListProvider.overrideWith((Ref ref) async => const []),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await tester.pump();
    await openRunningTab(tester);
    await pumpUntilFound(tester, find.byKey(const Key('ghost-control-chip')));
    await pumpUntilFound(tester, find.text('Ghost Run Off'));

    expect(find.byKey(const Key('settings-button')), findsNothing);
    expect(find.byKey(const Key('run-interval-button')), findsOneWidget);
    expect(find.text('Ghost Run Off'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ghost-control-chip')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('ghost-session-sheet')), findsNothing);
  });

  testWidgets('running tab uses the left action for interval settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          disableStartupWeightPromptOverride,
          runSessionListProvider.overrideWith(
            (Ref ref) async => sampleRunSessions(),
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
    await pumpUntilFound(
      tester,
      find.byKey(const Key('run-interval-sheet-scroll')),
    );

    expect(find.byKey(const Key('run-interval-sheet-scroll')), findsOneWidget);
    expect(find.byKey(const Key('ghost-toggle')), findsNothing);
  });
}

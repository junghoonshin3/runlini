import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/ui/run_session_summary_tile.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('selects and clears a ghost session from settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    await pumpUntilFound(tester, find.byKey(const Key('settings-button')));

    await tester.tap(find.byKey(const Key('settings-button')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-toggle')));

    expect(find.text('고스트 라이더'), findsWidgets);

    tester.widget<Switch>(find.byKey(const Key('ghost-toggle'))).onChanged!(
      true,
    );
    await pumpUntilFound(tester, find.byKey(const Key('ghost-session-sheet')));

    expect(find.byKey(const Key('ghost-session-sheet')), findsOneWidget);

    tester
        .widget<RunSessionSummaryTile>(
          find.byKey(const Key('ghost-session-item-fixture_han_river_push')),
        )
        .onTap!();
    await pumpUntilFound(
      tester,
      find.byKey(const Key('selected-ghost-summary')),
    );

    expect(find.byKey(const Key('selected-ghost-summary')), findsOneWidget);

    await tester.pageBack();
    await pumpUntilFound(tester, find.byKey(const Key('ghost-polyline-layer')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('ghost-polyline-layer')), findsOneWidget);
    expect(find.text('GHOST ON'), findsNothing);

    await tester.tap(find.byKey(const Key('settings-button')));
    await pumpUntilFound(tester, find.byKey(const Key('ghost-toggle')));

    tester.widget<Switch>(find.byKey(const Key('ghost-toggle'))).onChanged!(
      false,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('ghost-polyline-layer')), findsNothing);
    expect(find.text('GHOST OFF'), findsNothing);
  });
}

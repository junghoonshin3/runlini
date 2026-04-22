import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/location/location_stream_client.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('switches between history and running tabs', (
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
    await pumpUntilFound(tester, find.byKey(const Key('run-map')));

    await tester.tap(find.text('기록'));
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));

    expect(find.byKey(const Key('history-list')), findsOneWidget);
    expect(find.text('평균 페이스'), findsWidgets);

    await tester.tap(find.text('러닝'));
    await pumpUntilFound(tester, find.byKey(const Key('run-map')));

    expect(find.byKey(const Key('run-map')), findsOneWidget);
    expect(find.byKey(const Key('current-location-button')), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('opens a saved run detail from the history tab', (
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
    await pumpUntilFound(tester, find.byKey(const Key('run-map')));

    await tester.tap(find.text('기록'));
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));

    await tester.tap(
      find.byKey(const Key('history-session-fixture_morning_tempo')),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('run-finish-review-panel')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finish-route-preview')), findsOneWidget);
    expect(find.byKey(const Key('detail-chart-pace')), findsOneWidget);
    expect(find.text('Run Detail'), findsOneWidget);
    expect(find.byKey(const Key('save-run-button')), findsNothing);
    expect(find.byKey(const Key('discard-run-button')), findsNothing);

    await tester.tap(find.byKey(const Key('run-detail-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-finish-review-panel')), findsNothing);
    expect(find.byKey(const Key('history-list')), findsOneWidget);
  });

  testWidgets('deletes a saved run from the history detail screen', (
    WidgetTester tester,
  ) async {
    final sessionRepository = FakeRunSessionRepository(sampleRunSessions());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runSessionRepositoryProvider.overrideWithValue(sessionRepository),
          locationStreamClientProvider.overrideWithValue(
            const SilentLocationStreamClient(),
          ),
        ],
        child: const RunliniApp(),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('run-map')));

    await tester.tap(find.text('기록'));
    await pumpUntilFound(tester, find.byKey(const Key('history-list')));
    await tester.tap(
      find.byKey(const Key('history-session-fixture_morning_tempo')),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const Key('run-finish-review-panel')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('run-detail-more-button')));
    await tester.pumpAndSettle();

    expect(find.text('기록을 삭제할까요?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-delete-run-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('run-finish-review-panel')), findsNothing);
    expect(sessionRepository.savedSessions, hasLength(1));
    expect(
      find.byKey(const Key('history-session-fixture_morning_tempo')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('history-session-fixture_han_river_push')),
      findsOneWidget,
    );
  });
}

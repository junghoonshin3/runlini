import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/app/theme/app_theme.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/run_tracking/repo/run_settings_repository.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';
import 'package:runlini/features/settings/ui/settings_sync_section.dart';
import 'package:runlini/features/settings/ui/settings_tab_screen.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  testWidgets('Android Health card connects through Health Connect', (
    tester,
  ) async {
    final route = _HealthRoute();
    await _pumpSettings(tester, route, TargetPlatform.android);

    expect(find.text('Health Connect 연결'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-health-import-button')));
    await tester.pumpAndSettle();

    expect(route.connectionRequests, 1);
    expect(route.requestAuthorizationValues, [false]);
    expect(find.text('연결됨'), findsWidgets);
    expect(find.text('Health Connect 연결됨'), findsOneWidget);
  });

  testWidgets('iOS Health card uses the user-facing Health app name', (
    tester,
  ) async {
    await _pumpSettings(tester, _HealthRoute(), TargetPlatform.iOS);

    expect(find.text('건강 앱 연결'), findsOneWidget);
    expect(find.byKey(const Key('settings-wear-sync-button')), findsNothing);
  });
}

Future<void> _pumpSettings(
  WidgetTester tester,
  HealthRouteClient route,
  TargetPlatform platform,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsTargetPlatformProvider.overrideWithValue(platform),
        runSettingsRepositoryProvider.overrideWithValue(
          _FakeRunSettingsRepository(),
        ),
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(),
        ),
        healthRouteClientProvider.overrideWithValue(route),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SettingsTabScreen()),
      ),
    ),
  );
  await pumpUntilFound(tester, find.byKey(const Key('settings-tab-screen')));
  await tester.scrollUntilVisible(
    find.byKey(const Key('settings-health-import-button')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

class _HealthRoute implements HealthRouteClient {
  int connectionRequests = 0;
  final List<bool> requestAuthorizationValues = <bool>[];

  @override
  Future<HealthRouteConnectionStatus> checkConnection() async {
    return const HealthRouteConnectionStatus.connectionNeeded();
  }

  @override
  Future<HealthRouteConnectionStatus> requestConnection() async {
    connectionRequests += 1;
    return const HealthRouteConnectionStatus.connected();
  }

  @override
  Future<HealthRouteImportResult> importRecentSessions({
    required bool requestAuthorization,
  }) async {
    requestAuthorizationValues.add(requestAuthorization);
    return const HealthRouteImportResult.success([]);
  }
}

class _FakeRunSettingsRepository implements RunSettingsRepository {
  @override
  Future<void> deleteShoe(String id) async {}

  @override
  Future<RunSettingsState> loadSettings() async => const RunSettingsState();

  @override
  Future<List<RunShoe>> listShoes() async => const <RunShoe>[];

  @override
  Future<void> retireShoe(String id) async {}

  @override
  Future<void> saveSettings(RunSettingsState settings) async {}

  @override
  Future<void> saveShoe(RunShoe shoe) async {}
}

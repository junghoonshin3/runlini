import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';

import '../../helpers/runlini_widget_harness.dart';

void main() {
  test('syncWithUserAction requests Health authorization', () async {
    final route = _HealthRoute();
    final container = ProviderContainer(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(),
        ),
        healthRouteClientProvider.overrideWithValue(route),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(healthSyncControllerProvider.notifier)
        .syncWithUserAction();

    expect(route.requestAuthorizationValues, [true]);
  });

  test('syncIfAuthorized does not request Health authorization', () async {
    final route = _HealthRoute();
    final container = ProviderContainer(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(),
        ),
        healthRouteClientProvider.overrideWithValue(route),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(healthSyncControllerProvider.notifier)
        .syncIfAuthorized();

    expect(route.requestAuthorizationValues, [false]);
  });

  test('connectAndSync requests connection then imports silently', () async {
    final route = _HealthRoute();
    final container = ProviderContainer(
      overrides: [
        runSessionRepositoryProvider.overrideWithValue(
          FakeRunSessionRepository(),
        ),
        healthRouteClientProvider.overrideWithValue(route),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(healthSyncControllerProvider.notifier)
        .connectAndSync();

    expect(route.connectionRequests, 1);
    expect(route.requestAuthorizationValues, [false]);
  });
}

class _HealthRoute implements HealthRouteClient {
  int connectionRequests = 0;
  final List<bool> requestAuthorizationValues = <bool>[];

  @override
  Future<HealthRouteConnectionStatus> checkConnection() async {
    return const HealthRouteConnectionStatus.connected();
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

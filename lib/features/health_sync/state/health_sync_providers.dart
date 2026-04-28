import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/health/health_plugin_route_client.dart';
import 'package:runlini/core/health/health_route_client.dart';
import 'package:runlini/features/health_sync/service/health_sync_service.dart';
import 'package:runlini/features/health_sync/service/platform_health_sync_service.dart';
import 'package:runlini/features/health_sync/types/health_sync_status.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';

final healthRouteClientProvider = Provider<HealthRouteClient>((Ref ref) {
  return HealthPluginRouteClient();
});

final healthSyncServiceProvider = Provider<HealthSyncService>((Ref ref) {
  return PlatformHealthSyncService(
    routeClient: ref.watch(healthRouteClientProvider),
    repository: ref.watch(runSessionRepositoryProvider),
  );
});

class HealthSyncController extends AsyncNotifier<HealthSyncStatus> {
  @override
  FutureOr<HealthSyncStatus> build() {
    return const HealthSyncStatus.idle();
  }

  Future<HealthSyncStatus> syncIfAuthorized() {
    return _sync(requestAuthorization: false);
  }

  Future<HealthSyncStatus> syncWithUserAction() {
    return _sync(requestAuthorization: true);
  }

  Future<HealthSyncStatus> _sync({required bool requestAuthorization}) async {
    state = const AsyncValue<HealthSyncStatus>.data(HealthSyncStatus.syncing());
    final result = await AsyncValue.guard(
      () => ref
          .read(healthSyncServiceProvider)
          .syncRecentSessions(requestAuthorization: requestAuthorization),
    );
    state = result;
    if (result.hasValue) {
      final status = result.requireValue;
      ref.invalidate(runSessionListProvider);
      return status;
    }
    final status = HealthSyncStatus.failed(result.error.toString());
    state = AsyncValue<HealthSyncStatus>.data(status);
    return status;
  }
}

final healthSyncControllerProvider =
    AsyncNotifierProvider<HealthSyncController, HealthSyncStatus>(
      HealthSyncController.new,
    );

import 'package:runlini/features/run_tracking/types/run_session.dart';

enum HealthRouteImportStatus {
  success,
  authorizationRequired,
  unavailable,
  failed,
}

enum HealthRouteConnectionStatusKind {
  connected,
  connectionNeeded,
  unavailable,
  failed,
}

class HealthRouteConnectionStatus {
  const HealthRouteConnectionStatus({required this.kind, this.message});

  const HealthRouteConnectionStatus.connected()
    : this(kind: HealthRouteConnectionStatusKind.connected);

  const HealthRouteConnectionStatus.connectionNeeded([String? message])
    : this(
        kind: HealthRouteConnectionStatusKind.connectionNeeded,
        message: message,
      );

  const HealthRouteConnectionStatus.unavailable([String? message])
    : this(kind: HealthRouteConnectionStatusKind.unavailable, message: message);

  const HealthRouteConnectionStatus.failed([String? message])
    : this(kind: HealthRouteConnectionStatusKind.failed, message: message);

  final HealthRouteConnectionStatusKind kind;
  final String? message;
}

class HealthRouteImportResult {
  const HealthRouteImportResult({
    required this.status,
    this.sessions = const <RunSession>[],
    this.message,
  });

  const HealthRouteImportResult.success(List<RunSession> sessions)
    : this(status: HealthRouteImportStatus.success, sessions: sessions);

  const HealthRouteImportResult.authorizationRequired([String? message])
    : this(
        status: HealthRouteImportStatus.authorizationRequired,
        message: message,
      );

  const HealthRouteImportResult.unavailable([String? message])
    : this(status: HealthRouteImportStatus.unavailable, message: message);

  const HealthRouteImportResult.failed([String? message])
    : this(status: HealthRouteImportStatus.failed, message: message);

  final HealthRouteImportStatus status;
  final List<RunSession> sessions;
  final String? message;
}

abstract class HealthRouteClient {
  Future<HealthRouteConnectionStatus> checkConnection() async {
    return const HealthRouteConnectionStatus.unavailable(
      'Health connection is not available.',
    );
  }

  Future<HealthRouteConnectionStatus> requestConnection() async {
    return const HealthRouteConnectionStatus.unavailable(
      'Health connection is not available.',
    );
  }

  Future<HealthRouteImportResult> importRecentSessions({
    required bool requestAuthorization,
  });
}

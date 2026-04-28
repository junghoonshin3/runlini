import 'package:runlini/features/run_tracking/types/run_session.dart';

enum HealthRouteImportStatus {
  success,
  authorizationRequired,
  unavailable,
  failed,
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
  Future<HealthRouteImportResult> importRecentSessions({
    required bool requestAuthorization,
  });
}

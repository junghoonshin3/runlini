import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/repo/run_session_repository.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/watch_run_draft.dart';
import 'package:runlini/features/run_tracking/types/watch_run_platform.dart';

class WatchRunSessionImportService {
  const WatchRunSessionImportService({required RunSessionRepository repository})
    : _repository = repository;

  static const Distance _distance = Distance();

  final RunSessionRepository _repository;

  Future<RunSession?> importDraft(WatchRunDraft draft, {String? shoeId}) async {
    final built = buildSession(draft, shoeId: shoeId);
    if (await _repository.isDeletedExternalSession(built)) {
      return null;
    }

    final existing = await _findExistingSession(built);
    final session = existing == null
        ? built
        : built.copyWith(id: existing.id, shoeId: shoeId ?? existing.shoeId);

    await _repository.saveSession(session);
    return session;
  }

  RunSession buildSession(WatchRunDraft draft, {String? shoeId}) {
    final points = _normalizePoints(draft);
    final durationMs = _safeDurationMs(draft);
    final distanceM = _safeDistanceM(draft, points);
    return RunSession(
      id: _sessionId(draft),
      startedAt: draft.startedAt,
      endedAt: draft.endedAt,
      distanceM: distanceM,
      durationMs: durationMs,
      sourceSummary: _sourceSummary(draft),
      points: points,
      averageCadenceSpm: draft.averageCadenceSpm,
      caloriesKcal: draft.caloriesKcal,
      recordSource: RunSessionRecordSource.appLocal,
      captureSource: draft.platform.captureSource,
      externalId: _nonEmpty(draft.externalWorkoutId),
      syncStatus: RunSessionSyncStatus.localOnly,
      ghostSummary: draft.ghostSummary,
      shoeId: shoeId,
    );
  }

  Future<RunSession?> _findExistingSession(RunSession candidate) async {
    final sessions = await _repository.listSessions();
    for (final session in sessions) {
      if (session.id == candidate.id) {
        return session;
      }
    }
    final externalId = candidate.externalId;
    if (externalId == null) {
      return null;
    }
    for (final session in sessions) {
      if (session.recordSource == RunSessionRecordSource.appLocal &&
          session.captureSource == candidate.captureSource &&
          session.externalId == externalId) {
        return session;
      }
    }
    return null;
  }

  List<RunPoint> _normalizePoints(WatchRunDraft draft) {
    return draft.points
        .map((point) => point.copyWith(source: draft.platform.pointSource))
        .toList(growable: false);
  }

  int _safeDurationMs(WatchRunDraft draft) {
    if (draft.durationMs > 0) {
      return draft.durationMs;
    }
    final endedAt = draft.endedAt;
    if (endedAt == null || endedAt.isBefore(draft.startedAt)) {
      return 0;
    }
    return endedAt.difference(draft.startedAt).inMilliseconds;
  }

  double _safeDistanceM(WatchRunDraft draft, List<RunPoint> points) {
    if (draft.distanceM.isFinite && draft.distanceM > 0) {
      return draft.distanceM;
    }
    var meters = 0.0;
    for (var index = 1; index < points.length; index += 1) {
      meters += _distance.as(
        LengthUnit.Meter,
        LatLng(points[index - 1].latitude, points[index - 1].longitude),
        LatLng(points[index].latitude, points[index].longitude),
      );
    }
    return meters;
  }

  String _sessionId(WatchRunDraft draft) {
    final externalId = _nonEmpty(draft.externalWorkoutId);
    if (externalId == null) {
      return draft.id;
    }
    return 'watch:${draft.platform.name}:$externalId';
  }

  String _sourceSummary(WatchRunDraft draft) {
    final device = _nonEmpty(draft.sourceDeviceName);
    if (device == null) {
      return draft.platform.label;
    }
    return '${draft.platform.label} · $device';
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

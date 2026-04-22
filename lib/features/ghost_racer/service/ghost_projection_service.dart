import 'package:latlong2/latlong.dart';
import 'package:runlini/features/ghost_racer/service/run_session_interpolator.dart';
import 'package:runlini/features/ghost_racer/types/ghost_frame.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

abstract class GhostProjectionService {
  GhostFrame project({
    required RunPoint runnerPoint,
    required RunSession ghostSession,
    required int elapsedMs,
  });
}

class TimeBasedGhostProjectionService implements GhostProjectionService {
  const TimeBasedGhostProjectionService({this.tieThresholdMeters = 3});

  final double tieThresholdMeters;

  static const Distance _distance = Distance();

  @override
  GhostFrame project({
    required RunPoint runnerPoint,
    required RunSession ghostSession,
    required int elapsedMs,
  }) {
    final ghostPoint = interpolateRunPoint(
      session: ghostSession,
      elapsedMs: elapsedMs,
    );
    final gapMeters = _distance.as(
      LengthUnit.Meter,
      LatLng(runnerPoint.latitude, runnerPoint.longitude),
      LatLng(ghostPoint.latitude, ghostPoint.longitude),
    );

    return GhostFrame(
      runnerPoint: runnerPoint,
      ghostPoint: ghostPoint,
      gapMeters: gapMeters,
      relativeState: _relativeState(
        runnerPoint: runnerPoint,
        ghostPoint: ghostPoint,
        gapMeters: gapMeters,
      ),
    );
  }

  GhostRelativeState _relativeState({
    required RunPoint runnerPoint,
    required RunPoint ghostPoint,
    required double gapMeters,
  }) {
    if (gapMeters <= tieThresholdMeters) {
      return GhostRelativeState.level;
    }

    if (runnerPoint.timestampRelMs <= ghostPoint.timestampRelMs) {
      return GhostRelativeState.behind;
    }

    return GhostRelativeState.ahead;
  }
}

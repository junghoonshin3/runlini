import 'package:latlong2/latlong.dart';
import 'package:runlini/features/record_race/service/run_session_interpolator.dart';
import 'package:runlini/features/record_race/types/record_race_projection_frame.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

abstract class RecordRaceProjectionService {
  RecordRaceProjectionFrame project({
    required RunPoint runnerPoint,
    required RunSession recordRaceSession,
    required int elapsedMs,
  });
}

class TimeBasedRecordRaceProjectionService
    implements RecordRaceProjectionService {
  const TimeBasedRecordRaceProjectionService({this.tieThresholdMeters = 3});

  final double tieThresholdMeters;

  static const Distance _distance = Distance();

  @override
  RecordRaceProjectionFrame project({
    required RunPoint runnerPoint,
    required RunSession recordRaceSession,
    required int elapsedMs,
  }) {
    final recordRacePoint = interpolateRunPoint(
      session: recordRaceSession,
      elapsedMs: elapsedMs,
    );
    final gapMeters = _distance.as(
      LengthUnit.Meter,
      LatLng(runnerPoint.latitude, runnerPoint.longitude),
      LatLng(recordRacePoint.latitude, recordRacePoint.longitude),
    );

    return RecordRaceProjectionFrame(
      runnerPoint: runnerPoint,
      recordRacePoint: recordRacePoint,
      gapMeters: gapMeters,
      relativeState: _relativeState(
        runnerPoint: runnerPoint,
        recordRacePoint: recordRacePoint,
        gapMeters: gapMeters,
      ),
    );
  }

  RecordRaceRelativeState _relativeState({
    required RunPoint runnerPoint,
    required RunPoint recordRacePoint,
    required double gapMeters,
  }) {
    if (gapMeters <= tieThresholdMeters) {
      return RecordRaceRelativeState.level;
    }

    if (runnerPoint.timestampRelMs <= recordRacePoint.timestampRelMs) {
      return RecordRaceRelativeState.behind;
    }

    return RecordRaceRelativeState.ahead;
  }
}

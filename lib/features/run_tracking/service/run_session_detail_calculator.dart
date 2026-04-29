import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';

class RunSessionDetailCalculator {
  const RunSessionDetailCalculator();

  static const Distance _distance = Distance();

  RunSessionDetail calculate(
    RunSession session, {
    double splitDistanceM = 1000,
  }) {
    final distanceKm = session.distanceM / 1000;
    final safeSplitDistanceM = splitDistanceM.isFinite && splitDistanceM > 0
        ? splitDistanceM
        : 1000.0;
    return RunSessionDetail(
      distanceKm: distanceKm,
      durationMs: session.durationMs,
      averagePaceSecPerKm: distanceKm <= 0
          ? null
          : (session.durationMs / 1000) / distanceKm,
      averageSpeedKmh: _averageSpeed(distanceKm, session.durationMs),
      caloriesLabel: session.caloriesKcal == null
          ? '-- kcal'
          : '${session.caloriesKcal!.round()} kcal',
      averageHeartRateBpm: _averageHeartRate(session.points),
      elevationGainM: _elevationGain(session.points),
      splits: _splits(session.points, splitDistanceM: safeSplitDistanceM),
      paceSamplesSecPerKm: _paceSamples(session.points),
      speedSamplesKmh: _speedSamples(session.points),
      elevationSamplesM: session.points
          .where((point) => _isUsableElevation(point.elevationM))
          .map(
            (point) => RunMetricSample(
              elapsedMs: point.timestampRelMs,
              value: point.elevationM!,
            ),
          )
          .toList(growable: false),
      heartRateSamplesBpm: session.points
          .where((point) => point.heartRateBpm != null)
          .map(
            (point) => RunMetricSample(
              elapsedMs: point.timestampRelMs,
              value: point.heartRateBpm!.toDouble(),
            ),
          )
          .toList(growable: false),
    );
  }

  double _averageSpeed(double distanceKm, int durationMs) {
    if (distanceKm <= 0 || durationMs <= 0) {
      return 0;
    }
    return distanceKm / (durationMs / Duration.millisecondsPerHour);
  }

  int? _averageHeartRate(List<RunPoint> points) {
    final values = points.map((point) => point.heartRateBpm).whereType<int>();
    if (values.isEmpty) {
      return null;
    }
    return (values.reduce((left, right) => left + right) / values.length)
        .round();
  }

  double? _elevationGain(List<RunPoint> points) {
    final elevations = points
        .map((point) => point.elevationM)
        .where(_isUsableElevation)
        .cast<double>();
    if (elevations.length < 2) {
      return null;
    }
    var gain = 0.0;
    var previous = elevations.first;
    for (final elevation in elevations.skip(1)) {
      final delta = elevation - previous;
      if (delta > 0) {
        gain += delta;
      }
      previous = elevation;
    }
    return gain;
  }

  bool _isUsableElevation(double? elevation) {
    return elevation != null && elevation.isFinite && elevation.abs() <= 12000;
  }

  List<RunMetricSample> _speedSamples(List<RunPoint> points) {
    final direct = points
        .where(
          (point) =>
              point.speedMps != null &&
              point.speedMps!.isFinite &&
              point.speedMps! > 0,
        )
        .map(
          (point) => RunMetricSample(
            elapsedMs: point.timestampRelMs,
            value: point.speedMps! * 3.6,
          ),
        )
        .toList(growable: false);
    if (direct.isNotEmpty) {
      return direct;
    }
    if (points.length < 2) {
      return const <RunMetricSample>[];
    }

    final samples = <RunMetricSample>[];
    for (var index = 1; index < points.length; index += 1) {
      final previous = points[index - 1];
      final current = points[index];
      final elapsedMs = current.timestampRelMs - previous.timestampRelMs;
      if (elapsedMs <= 0) {
        continue;
      }
      final meters = _metersBetween(previous, current);
      samples.add(
        RunMetricSample(
          elapsedMs: current.timestampRelMs,
          value: (meters / (elapsedMs / 1000)) * 3.6,
        ),
      );
    }
    return samples;
  }

  List<RunMetricSample> _paceSamples(List<RunPoint> points) {
    final direct = points
        .where(
          (point) =>
              point.paceSecPerKm != null &&
              point.paceSecPerKm!.isFinite &&
              point.paceSecPerKm! > 0,
        )
        .map(
          (point) => RunMetricSample(
            elapsedMs: point.timestampRelMs,
            value: point.paceSecPerKm!,
          ),
        )
        .toList(growable: false);
    if (direct.isNotEmpty) {
      return direct;
    }
    if (points.length < 2) {
      return const <RunMetricSample>[];
    }

    final samples = <RunMetricSample>[];
    for (var index = 1; index < points.length; index += 1) {
      final previous = points[index - 1];
      final current = points[index];
      final elapsedMs = current.timestampRelMs - previous.timestampRelMs;
      final meters = _metersBetween(previous, current);
      if (elapsedMs <= 0 || meters <= 0) {
        continue;
      }
      samples.add(
        RunMetricSample(
          elapsedMs: current.timestampRelMs,
          value: (elapsedMs / 1000) / (meters / 1000),
        ),
      );
    }
    return samples;
  }

  List<RunSplitDetail> _splits(
    List<RunPoint> points, {
    required double splitDistanceM,
  }) {
    if (points.length < 2) {
      return const <RunSplitDetail>[];
    }

    final cumulativeMeters = _cumulativeMeters(points);
    final totalMeters = cumulativeMeters.last;
    if (totalMeters <= 0) {
      return const <RunSplitDetail>[];
    }

    final splits = <RunSplitDetail>[];
    var previousBoundaryM = 0.0;
    var previousBoundaryMs = 0;
    var index = 1;
    while (previousBoundaryM < totalMeters) {
      final nextBoundaryM = (previousBoundaryM + splitDistanceM).clamp(
        0,
        totalMeters,
      );
      final boundaryMs = _elapsedAtDistance(
        points: points,
        cumulativeMeters: cumulativeMeters,
        targetM: nextBoundaryM.toDouble(),
      );
      final actualSplitDistanceM = nextBoundaryM - previousBoundaryM;
      final splitDurationMs = boundaryMs - previousBoundaryMs;
      if (actualSplitDistanceM > 0 && splitDurationMs > 0) {
        splits.add(
          RunSplitDetail(
            index: index,
            distanceM: actualSplitDistanceM.toDouble(),
            durationMs: splitDurationMs,
            paceSecPerKm:
                (splitDurationMs / 1000) / (actualSplitDistanceM / 1000),
          ),
        );
      }
      previousBoundaryM = nextBoundaryM.toDouble();
      previousBoundaryMs = boundaryMs;
      index += 1;
    }
    return splits;
  }

  List<double> _cumulativeMeters(List<RunPoint> points) {
    final values = <double>[0];
    for (var index = 1; index < points.length; index += 1) {
      values.add(
        values.last + _metersBetween(points[index - 1], points[index]),
      );
    }
    return values;
  }

  int _elapsedAtDistance({
    required List<RunPoint> points,
    required List<double> cumulativeMeters,
    required double targetM,
  }) {
    for (var index = 1; index < cumulativeMeters.length; index += 1) {
      if (targetM > cumulativeMeters[index]) {
        continue;
      }
      final segmentM = cumulativeMeters[index] - cumulativeMeters[index - 1];
      final ratio = segmentM <= 0
          ? 0.0
          : ((targetM - cumulativeMeters[index - 1]) / segmentM)
                .clamp(0.0, 1.0)
                .toDouble();
      final startMs = points[index - 1].timestampRelMs;
      final endMs = points[index].timestampRelMs;
      return startMs + ((endMs - startMs) * ratio).round();
    }
    return points.last.timestampRelMs;
  }

  double _metersBetween(RunPoint previous, RunPoint current) {
    return _distance.as(
      LengthUnit.Meter,
      LatLng(previous.latitude, previous.longitude),
      LatLng(current.latitude, current.longitude),
    );
  }
}

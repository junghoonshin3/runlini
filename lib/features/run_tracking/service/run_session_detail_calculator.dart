import 'package:runlini/core/location/run_pace_sample_sanitizer.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';
import 'package:runlini/features/run_tracking/types/run_session_detail.dart';

class RunSessionDetailCalculator {
  const RunSessionDetailCalculator({
    this.routeSegmenter = const RunRouteSegmenter(),
  });

  static const _paceSanitizer = RunPaceSampleSanitizer();

  final RunRouteSegmenter routeSegmenter;

  RunSessionDetail calculate(
    RunSession session, {
    double splitDistanceM = 1000,
  }) {
    final route = routeSegmenter.segment(session.points);
    final routeDistanceM = session.points.length < 2
        ? session.distanceM
        : route.distanceM;
    final metricPoints = route.metricPoints;
    final distanceKm = routeDistanceM / 1000;
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
      averageCadenceSpm: session.averageCadenceSpm,
      caloriesLabel: session.caloriesKcal == null
          ? '-- kcal'
          : '${session.caloriesKcal!.round()} kcal',
      averageHeartRateBpm: _averageHeartRate(session.points),
      elevationGainM: _elevationGain(session.points),
      splits: _splits(route, splitDistanceM: safeSplitDistanceM),
      paceSamplesSecPerKm: _paceSamples(metricPoints, route.transitions),
      speedSamplesKmh: _speedSamples(metricPoints, route.transitions),
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
      cadenceSamplesSpm: session.points
          .where((point) => _isUsableCadence(point.cadenceSpm))
          .map(
            (point) => RunMetricSample(
              elapsedMs: point.timestampRelMs,
              value: point.cadenceSpm!,
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

  bool _isUsableCadence(double? cadenceSpm) {
    return cadenceSpm != null &&
        cadenceSpm.isFinite &&
        cadenceSpm > 0 &&
        cadenceSpm <= 260;
  }

  List<RunMetricSample> _speedSamples(
    List<RunPoint> points,
    List<RunRouteTransition> transitions,
  ) {
    final direct = points
        .where(
          (point) =>
              point.speedMps != null &&
              point.speedMps!.isFinite &&
              point.speedMps! > 0 &&
              point.speedMps! <= routeSegmenter.maxBridgeSpeedMps,
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
    if (transitions.isEmpty) {
      return const <RunMetricSample>[];
    }

    final samples = <RunMetricSample>[];
    for (final transition in transitions) {
      samples.add(
        RunMetricSample(
          elapsedMs: transition.current.timestampRelMs,
          value: (transition.distanceM / (transition.elapsedMs / 1000)) * 3.6,
        ),
      );
    }
    return samples;
  }

  List<RunMetricSample> _paceSamples(
    List<RunPoint> points,
    List<RunRouteTransition> transitions,
  ) {
    final direct = points
        .where(
          (point) =>
              _paceSanitizer.isRenderablePace(point.paceSecPerKm) &&
              (point.speedMps == null ||
                  point.speedMps! <= routeSegmenter.maxBridgeSpeedMps),
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
    if (transitions.isEmpty) {
      return const <RunMetricSample>[];
    }

    final samples = <RunMetricSample>[];
    for (final transition in transitions) {
      final pace =
          (transition.elapsedMs / 1000) / (transition.distanceM / 1000);
      if (!_paceSanitizer.isRenderablePace(pace)) {
        continue;
      }
      samples.add(
        RunMetricSample(
          elapsedMs: transition.current.timestampRelMs,
          value: pace,
        ),
      );
    }
    return samples;
  }

  List<RunSplitDetail> _splits(
    RunRouteSegments route, {
    required double splitDistanceM,
  }) {
    final transitions = route.transitions;
    if (transitions.isEmpty) {
      return const <RunSplitDetail>[];
    }

    final cumulativeMeters = _cumulativeMeters(transitions);
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
        transitions: transitions,
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

  List<double> _cumulativeMeters(List<RunRouteTransition> transitions) {
    final values = <double>[0];
    for (final transition in transitions) {
      values.add(values.last + transition.distanceM);
    }
    return values;
  }

  int _elapsedAtDistance({
    required List<RunRouteTransition> transitions,
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
      final transition = transitions[index - 1];
      final startMs = transition.previous.timestampRelMs;
      final endMs = transition.current.timestampRelMs;
      return startMs + ((endMs - startMs) * ratio).round();
    }
    return transitions.last.current.timestampRelMs;
  }
}

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class RunRouteSegmenter {
  const RunRouteSegmenter({
    this.maxBridgeSpeedMps = 7.0,
    this.maxHorizontalAccuracyM = 35,
    this.longGapMs = 30 * 1000,
    this.longGapDistanceM = 100,
  });

  final double maxBridgeSpeedMps;
  final double maxHorizontalAccuracyM;
  final int longGapMs;
  final double longGapDistanceM;

  static const Distance _distance = Distance();

  RunRouteSegments segment(List<RunPoint> points) {
    if (points.isEmpty) {
      return const RunRouteSegments(segments: [], transitions: []);
    }

    final segments = <List<RunPoint>>[];
    final transitions = <RunRouteTransition>[];
    var current = <RunPoint>[];

    for (final point in points) {
      if (_hasPoorAccuracy(point)) {
        if (current.isNotEmpty) {
          segments.add(List<RunPoint>.unmodifiable(current));
          current = <RunPoint>[];
        }
        continue;
      }
      if (current.isEmpty) {
        current.add(point);
        continue;
      }

      final previous = current.last;
      final transition = _transition(previous, point);
      if (!transition.isAccepted) {
        segments.add(List<RunPoint>.unmodifiable(current));
        current = <RunPoint>[point];
        continue;
      }

      current.add(point);
      transitions.add(transition);
    }

    if (current.isNotEmpty) {
      segments.add(List<RunPoint>.unmodifiable(current));
    }

    return RunRouteSegments(
      segments: List<List<RunPoint>>.unmodifiable(segments),
      transitions: List<RunRouteTransition>.unmodifiable(transitions),
    );
  }

  RunRouteTransition _transition(RunPoint previous, RunPoint current) {
    final elapsedMs = current.timestampRelMs - previous.timestampRelMs;
    final distanceM = _metersBetween(previous, current);
    if (elapsedMs <= 0 || !distanceM.isFinite) {
      return RunRouteTransition.rejected(previous, current, distanceM);
    }

    final speedMps = distanceM / (elapsedMs / 1000);
    final isLongGapBridge =
        _usesGpsGapPolicy(previous, current) &&
        elapsedMs > longGapMs &&
        distanceM > longGapDistanceM;
    final isTooFast = speedMps > maxBridgeSpeedMps;
    return RunRouteTransition(
      previous: previous,
      current: current,
      distanceM: distanceM,
      elapsedMs: elapsedMs,
      isAccepted: !isLongGapBridge && !isTooFast,
    );
  }

  bool _hasPoorAccuracy(RunPoint point) {
    final accuracy = point.horizontalAccuracyM;
    return accuracy != null &&
        accuracy.isFinite &&
        accuracy > maxHorizontalAccuracyM;
  }

  bool _usesGpsGapPolicy(RunPoint previous, RunPoint current) {
    return _isLiveGpsSource(previous.source) ||
        _isLiveGpsSource(current.source);
  }

  bool _isLiveGpsSource(RunPointSource source) {
    return source == RunPointSource.deviceGps ||
        source == RunPointSource.wearOs ||
        source == RunPointSource.watchOs;
  }

  double _metersBetween(RunPoint previous, RunPoint current) {
    return _distance.as(
      LengthUnit.Meter,
      LatLng(previous.latitude, previous.longitude),
      LatLng(current.latitude, current.longitude),
    );
  }
}

class RunRouteSegments {
  const RunRouteSegments({required this.segments, required this.transitions});

  final List<List<RunPoint>> segments;
  final List<RunRouteTransition> transitions;

  double get distanceM {
    return transitions.fold<double>(
      0,
      (total, transition) => total + transition.distanceM,
    );
  }

  List<RunPoint> get metricPoints {
    return <RunPoint>[
      for (var index = 0; index < segments.length; index += 1)
        ...segments[index].skip(
          index == 0 ? 0 : math.min(1, segments[index].length),
        ),
    ];
  }
}

class RunRouteTransition {
  const RunRouteTransition({
    required this.previous,
    required this.current,
    required this.distanceM,
    required this.elapsedMs,
    required this.isAccepted,
  });

  factory RunRouteTransition.rejected(
    RunPoint previous,
    RunPoint current,
    double distanceM,
  ) {
    return RunRouteTransition(
      previous: previous,
      current: current,
      distanceM: distanceM,
      elapsedMs: current.timestampRelMs - previous.timestampRelMs,
      isAccepted: false,
    );
  }

  final RunPoint previous;
  final RunPoint current;
  final double distanceM;
  final int elapsedMs;
  final bool isAccepted;
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

enum RouteSpeedInsightBucket { fast, average, slow }

class RouteSpeedInsight {
  const RouteSpeedInsight({
    required this.bucket,
    required this.distanceM,
    required this.elapsedMs,
  });

  final RouteSpeedInsightBucket bucket;
  final double distanceM;
  final int elapsedMs;

  double get paceSecPerKm => (elapsedMs / 1000) / (distanceM / 1000);

  double get speedKmh => (distanceM / 1000) / (elapsedMs / 3600000);
}

class RouteSpeedInsightBuilder {
  const RouteSpeedInsightBuilder({
    this.fastRatio = 0.95,
    this.slowRatio = 1.14,
  });

  final double fastRatio;
  final double slowRatio;

  static const Distance _distance = Distance();

  List<RouteSpeedInsight> build(
    List<List<RunPoint>> routeSegments, {
    double fallbackBaselinePaceSecPerKm = 0,
  }) {
    final transitions = <_RouteSpeedTransition>[];
    for (final segment in routeSegments) {
      for (var index = 1; index < segment.length; index += 1) {
        final transition = _transition(segment[index - 1], segment[index]);
        if (transition != null) {
          transitions.add(transition);
        }
      }
    }
    if (transitions.isEmpty) {
      return const <RouteSpeedInsight>[];
    }

    final baseline =
        _median(
          transitions.map((transition) => transition.paceSecPerKm).toList(),
        ) ??
        fallbackBaselinePaceSecPerKm;
    if (baseline <= 0 || !baseline.isFinite) {
      return const <RouteSpeedInsight>[];
    }

    final buckets = <RouteSpeedInsightBucket, _RouteSpeedAccumulator>{
      for (final bucket in RouteSpeedInsightBucket.values)
        bucket: _RouteSpeedAccumulator(),
    };
    for (final transition in transitions) {
      buckets[_bucketFor(transition.paceSecPerKm / baseline)]!.add(transition);
    }

    return <RouteSpeedInsight>[
      for (final bucket in RouteSpeedInsightBucket.values)
        if (buckets[bucket]!.hasData)
          RouteSpeedInsight(
            bucket: bucket,
            distanceM: buckets[bucket]!.distanceM,
            elapsedMs: buckets[bucket]!.elapsedMs,
          ),
    ];
  }

  RouteSpeedInsightBucket _bucketFor(double paceRatio) {
    if (!paceRatio.isFinite) {
      return RouteSpeedInsightBucket.average;
    }
    if (paceRatio <= fastRatio) {
      return RouteSpeedInsightBucket.fast;
    }
    if (paceRatio <= slowRatio) {
      return RouteSpeedInsightBucket.average;
    }
    return RouteSpeedInsightBucket.slow;
  }

  static _RouteSpeedTransition? _transition(
    RunPoint previous,
    RunPoint current,
  ) {
    final elapsedMs = current.timestampRelMs - previous.timestampRelMs;
    if (elapsedMs <= 0) {
      return null;
    }

    final distanceM = _distance.as(
      LengthUnit.Meter,
      LatLng(previous.latitude, previous.longitude),
      LatLng(current.latitude, current.longitude),
    );
    if (!distanceM.isFinite || distanceM <= 0) {
      return null;
    }

    return _RouteSpeedTransition(distanceM: distanceM, elapsedMs: elapsedMs);
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) {
      return null;
    }

    final sorted = values.toList()..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }

    return (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

extension RouteSpeedInsightBucketUi on RouteSpeedInsightBucket {
  String get colorLabel {
    return switch (this) {
      RouteSpeedInsightBucket.fast => '초록',
      RouteSpeedInsightBucket.average => '노랑/주황',
      RouteSpeedInsightBucket.slow => '빨강',
    };
  }

  String get speedLabel {
    return switch (this) {
      RouteSpeedInsightBucket.fast => '빠른 구간',
      RouteSpeedInsightBucket.average => '평균 구간',
      RouteSpeedInsightBucket.slow => '느린 구간',
    };
  }

  Color get color {
    return switch (this) {
      RouteSpeedInsightBucket.fast => AppColors.voltGreen,
      RouteSpeedInsightBucket.average => AppColors.amber,
      RouteSpeedInsightBucket.slow => AppColors.electricRed,
    };
  }
}

class _RouteSpeedTransition {
  const _RouteSpeedTransition({
    required this.distanceM,
    required this.elapsedMs,
  });

  final double distanceM;
  final int elapsedMs;

  double get paceSecPerKm => (elapsedMs / 1000) / (distanceM / 1000);
}

class _RouteSpeedAccumulator {
  double distanceM = 0;
  int elapsedMs = 0;

  bool get hasData => distanceM > 0 && elapsedMs > 0;

  void add(_RouteSpeedTransition transition) {
    distanceM += transition.distanceM;
    elapsedMs += transition.elapsedMs;
  }
}

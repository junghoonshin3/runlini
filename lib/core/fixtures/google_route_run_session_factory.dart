import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';
import 'package:runlini/features/run_tracking/types/run_session.dart';

class GoogleRouteRunSessionFactory {
  const GoogleRouteRunSessionFactory();

  static const Distance _distance = Distance();
  static const List<RoutePaceBand> defaultPaceBands = <RoutePaceBand>[
    RoutePaceBand(untilProgress: 0.25, factor: 0.82),
    RoutePaceBand(untilProgress: 0.5, factor: 0.98),
    RoutePaceBand(untilProgress: 0.75, factor: 1.09),
    RoutePaceBand(untilProgress: 1, factor: 1.18),
  ];

  static const List<RoutePaceBand> rollingPaceBands = <RoutePaceBand>[
    RoutePaceBand(untilProgress: 0.12, factor: 0.92),
    RoutePaceBand(untilProgress: 0.24, factor: 1.05),
    RoutePaceBand(untilProgress: 0.36, factor: 0.87),
    RoutePaceBand(untilProgress: 0.48, factor: 1.14),
    RoutePaceBand(untilProgress: 0.6, factor: 0.98),
    RoutePaceBand(untilProgress: 0.72, factor: 1.2),
    RoutePaceBand(untilProgress: 0.84, factor: 0.9),
    RoutePaceBand(untilProgress: 1, factor: 1.08),
  ];

  RunSession fromGoogleRoutesResponse(
    Map<String, dynamic> response, {
    required String id,
    required DateTime startedAt,
    required String sourceSummary,
    required double averagePaceSecPerKm,
    required double averageCadenceSpm,
    List<RoutePaceBand> paceBands = defaultPaceBands,
  }) {
    final routes = response['routes'] as List<dynamic>;
    final route = routes.first as Map<String, dynamic>;
    final distanceM = (route['distanceMeters'] as num).toDouble();
    final coordinates = _coordinatesFromRoute(route);
    final durationMs = ((distanceM / 1000) * averagePaceSecPerKm * 1000)
        .round();
    final cumulativeMeters = _cumulativeMeters(coordinates);
    final segmentPaces = _segmentPaces(
      cumulativeMeters: cumulativeMeters,
      targetDurationMs: durationMs,
      averagePaceSecPerKm: averagePaceSecPerKm,
      paceBands: paceBands,
    );

    final points = <RunPoint>[];
    var elapsedMs = 0.0;
    for (var index = 0; index < coordinates.length; index += 1) {
      final coordinate = coordinates[index];
      if (index > 0) {
        final segmentMeters =
            cumulativeMeters[index] - cumulativeMeters[index - 1];
        elapsedMs += (segmentMeters / 1000) * segmentPaces[index - 1] * 1000;
      }
      points.add(
        RunPoint(
          latitude: coordinate.latitude,
          longitude: coordinate.longitude,
          timestampRelMs: index == coordinates.length - 1
              ? durationMs
              : elapsedMs.round(),
          paceSecPerKm: _paceAt(
            segmentPaces,
            pointIndex: index,
            fallbackPaceSecPerKm: averagePaceSecPerKm,
          ),
          source: RunPointSource.simulated,
        ),
      );
    }

    return RunSession(
      id: id,
      startedAt: startedAt,
      endedAt: startedAt.add(Duration(milliseconds: durationMs)),
      distanceM: distanceM,
      durationMs: durationMs,
      sourceSummary: sourceSummary,
      points: points,
      averageCadenceSpm: averageCadenceSpm,
    );
  }

  List<_FixtureCoordinate> _coordinatesFromRoute(Map<String, dynamic> route) {
    final polyline = route['polyline'] as Map<String, dynamic>;
    final lineString = polyline['geoJsonLinestring'] as Map<String, dynamic>;
    final coordinates = lineString['coordinates'] as List<dynamic>;
    return coordinates
        .map((dynamic rawCoordinate) {
          final pair = rawCoordinate as List<dynamic>;
          return _FixtureCoordinate(
            latitude: (pair[1] as num).toDouble(),
            longitude: (pair[0] as num).toDouble(),
          );
        })
        .toList(growable: false);
  }

  List<double> _cumulativeMeters(List<_FixtureCoordinate> coordinates) {
    if (coordinates.isEmpty) {
      return const <double>[0];
    }

    final cumulativeMeters = <double>[0];
    for (var index = 1; index < coordinates.length; index += 1) {
      final previous = coordinates[index - 1];
      final current = coordinates[index];
      final segmentMeters = _distance.as(
        LengthUnit.Meter,
        LatLng(previous.latitude, previous.longitude),
        LatLng(current.latitude, current.longitude),
      );
      cumulativeMeters.add(cumulativeMeters.last + segmentMeters);
    }

    return cumulativeMeters;
  }

  List<double> _segmentPaces({
    required List<double> cumulativeMeters,
    required int targetDurationMs,
    required double averagePaceSecPerKm,
    required List<RoutePaceBand> paceBands,
  }) {
    if (cumulativeMeters.length < 2) {
      return const <double>[];
    }

    final rawPaces = <double>[
      for (var index = 1; index < cumulativeMeters.length; index += 1)
        averagePaceSecPerKm *
            _paceFactor(
              progress: (index - 1) / (cumulativeMeters.length - 1),
              paceBands: paceBands,
            ),
    ];
    final rawDurationMs = _durationMsForPaces(cumulativeMeters, rawPaces);
    if (rawDurationMs <= 0) {
      return List<double>.filled(
        cumulativeMeters.length - 1,
        averagePaceSecPerKm,
      );
    }

    final scale = targetDurationMs / rawDurationMs;
    return rawPaces.map((double pace) => pace * scale).toList(growable: false);
  }

  double _durationMsForPaces(
    List<double> cumulativeMeters,
    List<double> paces,
  ) {
    var durationMs = 0.0;
    for (var index = 1; index < cumulativeMeters.length; index += 1) {
      final segmentMeters =
          cumulativeMeters[index] - cumulativeMeters[index - 1];
      durationMs += (segmentMeters / 1000) * paces[index - 1] * 1000;
    }
    return durationMs;
  }

  double _paceAt(
    List<double> segmentPaces, {
    required int pointIndex,
    required double fallbackPaceSecPerKm,
  }) {
    if (segmentPaces.isEmpty) {
      return fallbackPaceSecPerKm;
    }

    final paceIndex = (pointIndex == 0 ? 0 : pointIndex - 1)
        .clamp(0, segmentPaces.length - 1)
        .toInt();
    return segmentPaces[paceIndex];
  }

  double _paceFactor({
    required double progress,
    required List<RoutePaceBand> paceBands,
  }) {
    if (paceBands.isEmpty) {
      return 1;
    }

    for (final band in paceBands) {
      if (progress < band.untilProgress) {
        return band.factor;
      }
    }
    return paceBands.last.factor;
  }
}

class RoutePaceBand {
  const RoutePaceBand({required this.untilProgress, required this.factor});

  final double untilProgress;
  final double factor;
}

class _FixtureCoordinate {
  const _FixtureCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

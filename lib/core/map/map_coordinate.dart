import 'package:flutter/foundation.dart';
import 'package:runlini/features/run_tracking/types/live_location_sample.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

@immutable
class MapCoordinate {
  const MapCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  MapCoordinate copyWith({double? latitude, double? longitude}) {
    return MapCoordinate(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MapCoordinate &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'MapCoordinate(lat: $latitude, lng: $longitude)';
}

extension RunPointMapCoordinateX on RunPoint {
  MapCoordinate toMapCoordinate() {
    return MapCoordinate(latitude: latitude, longitude: longitude);
  }
}

extension LiveLocationSampleMapCoordinateX on LiveLocationSample {
  MapCoordinate toMapCoordinate() {
    return MapCoordinate(latitude: latitude, longitude: longitude);
  }
}

List<MapCoordinate> mapCoordinatesFromRunPoints(Iterable<RunPoint> points) {
  return points
      .map((RunPoint point) => point.toMapCoordinate())
      .toList(growable: false);
}

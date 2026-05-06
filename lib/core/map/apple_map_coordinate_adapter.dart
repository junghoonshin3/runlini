import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amap;
import 'package:runlini/core/map/map_coordinate.dart';

amap.LatLngBounds appleBoundsFor(List<MapCoordinate> points) {
  var south = points.first.latitude;
  var north = points.first.latitude;
  var west = points.first.longitude;
  var east = points.first.longitude;
  for (final point in points.skip(1)) {
    if (point.latitude < south) south = point.latitude;
    if (point.latitude > north) north = point.latitude;
    if (point.longitude < west) west = point.longitude;
    if (point.longitude > east) east = point.longitude;
  }
  if (south == north) {
    south -= 0.0001;
    north += 0.0001;
  }
  if (west == east) {
    west -= 0.0001;
    east += 0.0001;
  }
  return amap.LatLngBounds(
    southwest: amap.LatLng(south, west),
    northeast: amap.LatLng(north, east),
  );
}

extension AppleMapCoordinateAdapter on MapCoordinate {
  amap.LatLng toAppleLatLng() => amap.LatLng(latitude, longitude);
}

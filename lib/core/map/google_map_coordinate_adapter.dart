import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:runlini/core/map/map_coordinate.dart';

gmap.LatLngBounds googleBoundsFor(List<MapCoordinate> points) {
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
  return gmap.LatLngBounds(
    southwest: gmap.LatLng(south, west),
    northeast: gmap.LatLng(north, east),
  );
}

extension GoogleMapCoordinateAdapter on MapCoordinate {
  gmap.LatLng toGoogleLatLng() => gmap.LatLng(latitude, longitude);
}

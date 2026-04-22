import 'package:flutter/material.dart';
import 'package:runlini/core/map/map_coordinate.dart';

class MapPolylineSegment {
  const MapPolylineSegment({required this.points, required this.color});

  final List<MapCoordinate> points;
  final Color color;
}

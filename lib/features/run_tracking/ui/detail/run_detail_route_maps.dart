import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amap;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:runlini/core/map/apple_map_coordinate_adapter.dart';
import 'package:runlini/core/map/google_map_coordinate_adapter.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';

class GoogleDetailRouteMap extends StatefulWidget {
  const GoogleDetailRouteMap({
    super.key,
    required this.routePoints,
    required this.routeSegments,
  });

  final List<MapCoordinate> routePoints;
  final List<MapPolylineSegment> routeSegments;

  @override
  State<GoogleDetailRouteMap> createState() => _GoogleDetailRouteMapState();
}

class _GoogleDetailRouteMapState extends State<GoogleDetailRouteMap> {
  gmap.GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: gmap.GoogleMap(
        key: const Key('detail-route-map'),
        initialCameraPosition: gmap.CameraPosition(
          target: centerOfRoute(widget.routePoints).toGoogleLatLng(),
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _controller = controller;
          _fitRoute();
        },
        mapType: gmap.MapType.normal,
        compassEnabled: false,
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        rotateGesturesEnabled: false,
        scrollGesturesEnabled: false,
        tiltGesturesEnabled: false,
        zoomControlsEnabled: false,
        zoomGesturesEnabled: false,
        trafficEnabled: false,
        polylines: {
          for (var index = 0; index < widget.routeSegments.length; index += 1)
            _polyline(widget.routeSegments[index], index),
        },
      ),
    );
  }

  gmap.Polyline _polyline(MapPolylineSegment segment, int index) {
    return gmap.Polyline(
      polylineId: gmap.PolylineId('detail-route-polyline-$index'),
      points: segment.points.map((point) => point.toGoogleLatLng()).toList(),
      color: segment.color,
      width: 6,
      startCap: gmap.Cap.roundCap,
      endCap: gmap.Cap.roundCap,
      jointType: gmap.JointType.round,
    );
  }

  void _fitRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controller;
      if (!mounted || controller == null) return;
      controller.animateCamera(
        gmap.CameraUpdate.newLatLngBounds(
          googleBoundsFor(widget.routePoints),
          44,
        ),
      );
    });
  }
}

class AppleDetailRouteMap extends StatefulWidget {
  const AppleDetailRouteMap({
    super.key,
    required this.routePoints,
    required this.routeSegments,
  });

  final List<MapCoordinate> routePoints;
  final List<MapPolylineSegment> routeSegments;

  @override
  State<AppleDetailRouteMap> createState() => _AppleDetailRouteMapState();
}

class _AppleDetailRouteMapState extends State<AppleDetailRouteMap> {
  amap.AppleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: amap.AppleMap(
        key: const Key('detail-route-map'),
        initialCameraPosition: amap.CameraPosition(
          target: centerOfRoute(widget.routePoints).toAppleLatLng(),
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _controller = controller;
          _fitRoute();
        },
        compassEnabled: false,
        mapType: amap.MapType.standard,
        pitchGesturesEnabled: false,
        rotateGesturesEnabled: false,
        scrollGesturesEnabled: false,
        trafficEnabled: false,
        zoomGesturesEnabled: false,
        polylines: {
          for (var index = 0; index < widget.routeSegments.length; index += 1)
            _polyline(widget.routeSegments[index], index),
        },
      ),
    );
  }

  amap.Polyline _polyline(MapPolylineSegment segment, int index) {
    return amap.Polyline(
      polylineId: amap.PolylineId('detail-route-polyline-$index'),
      points: segment.points.map((point) => point.toAppleLatLng()).toList(),
      color: segment.color,
      width: 6,
      polylineCap: amap.Cap.roundCap,
      jointType: amap.JointType.round,
    );
  }

  void _fitRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controller;
      if (!mounted || controller == null) return;
      controller.animateCamera(
        amap.CameraUpdate.newLatLngBounds(
          appleBoundsFor(widget.routePoints),
          44,
        ),
      );
    });
  }
}

MapCoordinate centerOfRoute(List<MapCoordinate> points) {
  final latitudes = points.map((point) => point.latitude);
  final longitudes = points.map((point) => point.longitude);
  return MapCoordinate(
    latitude: (latitudes.reduce(_min) + latitudes.reduce(_max)) / 2,
    longitude: (longitudes.reduce(_min) + longitudes.reduce(_max)) / 2,
  );
}

double _min(double left, double right) => left < right ? left : right;
double _max(double left, double right) => left > right ? left : right;

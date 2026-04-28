import 'dart:io';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amap;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/fake_run_map_surface.dart';
import 'package:runlini/core/map/map_config_client.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');

class RunDetailRoutePreview extends ConsumerWidget {
  const RunDetailRoutePreview({super.key, required this.points});

  final List<RunPoint> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routePoints = mapCoordinatesFromRunPoints(points);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        key: const Key('finish-route-preview'),
        height: 210,
        width: double.infinity,
        child: _RoutePreviewBody(routePoints: routePoints),
      ),
    );
  }
}

class _RoutePreviewBody extends ConsumerWidget {
  const _RoutePreviewBody({required this.routePoints});

  final List<MapCoordinate> routePoints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (routePoints.length < 2) {
      return const _RoutePreviewFallback(message: '경로 데이터가 부족해요.');
    }

    if (_isFlutterTest || (!Platform.isAndroid && !Platform.isIOS)) {
      return FakeRunMapSurface(
        mapCenter: _centerOf(routePoints),
        currentRunnerPolylinePoints: routePoints,
        ghostPolylinePoints: const <MapCoordinate>[],
        ghostPolylineSegments: const [],
      );
    }

    if (Platform.isIOS) {
      return _AppleDetailRouteMap(routePoints: routePoints);
    }

    final configuredAsync = ref.watch(androidGoogleMapsConfiguredProvider);
    return configuredAsync.when(
      data: (configured) {
        if (!configured) {
          return const _RoutePreviewFallback(
            message: 'Google Maps 키가 설정되지 않았어요.',
          );
        }
        return _GoogleDetailRouteMap(routePoints: routePoints);
      },
      loading: () => const _RoutePreviewFallback(message: '지도를 준비하고 있어요.'),
      error: (_, _) =>
          const _RoutePreviewFallback(message: '지도 설정을 확인하지 못했어요.'),
    );
  }
}

class _GoogleDetailRouteMap extends StatefulWidget {
  const _GoogleDetailRouteMap({required this.routePoints});

  final List<MapCoordinate> routePoints;

  @override
  State<_GoogleDetailRouteMap> createState() => _GoogleDetailRouteMapState();
}

class _GoogleDetailRouteMapState extends State<_GoogleDetailRouteMap> {
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
          target: _centerOf(widget.routePoints).toGoogleLatLng(),
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
          gmap.Polyline(
            polylineId: const gmap.PolylineId('detail-route-polyline'),
            points: widget.routePoints
                .map((point) => point.toGoogleLatLng())
                .toList(growable: false),
            color: AppColors.voltGreen,
            width: 6,
            startCap: gmap.Cap.roundCap,
            endCap: gmap.Cap.roundCap,
            jointType: gmap.JointType.round,
          ),
        },
      ),
    );
  }

  void _fitRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controller;
      if (!mounted || controller == null) {
        return;
      }
      controller.animateCamera(
        gmap.CameraUpdate.newLatLngBounds(
          _googleBoundsFor(widget.routePoints),
          44,
        ),
      );
    });
  }
}

class _AppleDetailRouteMap extends StatefulWidget {
  const _AppleDetailRouteMap({required this.routePoints});

  final List<MapCoordinate> routePoints;

  @override
  State<_AppleDetailRouteMap> createState() => _AppleDetailRouteMapState();
}

class _AppleDetailRouteMapState extends State<_AppleDetailRouteMap> {
  amap.AppleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: amap.AppleMap(
        key: const Key('detail-route-map'),
        initialCameraPosition: amap.CameraPosition(
          target: _centerOf(widget.routePoints).toAppleLatLng(),
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
          amap.Polyline(
            polylineId: amap.PolylineId('detail-route-polyline'),
            points: widget.routePoints
                .map((point) => point.toAppleLatLng())
                .toList(growable: false),
            color: AppColors.voltGreen,
            width: 6,
            polylineCap: amap.Cap.roundCap,
            jointType: amap.JointType.round,
          ),
        },
      ),
    );
  }

  void _fitRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _controller;
      if (!mounted || controller == null) {
        return;
      }
      controller.animateCamera(
        amap.CameraUpdate.newLatLngBounds(
          _appleBoundsFor(widget.routePoints),
          44,
        ),
      );
    });
  }
}

class _RoutePreviewFallback extends StatelessWidget {
  const _RoutePreviewFallback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.panel,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

MapCoordinate _centerOf(List<MapCoordinate> points) {
  final bounds = _boundsFor(points);
  return MapCoordinate(
    latitude: (bounds.south + bounds.north) / 2,
    longitude: (bounds.west + bounds.east) / 2,
  );
}

_RouteBounds _boundsFor(List<MapCoordinate> points) {
  var south = points.first.latitude;
  var north = points.first.latitude;
  var west = points.first.longitude;
  var east = points.first.longitude;
  for (final point in points.skip(1)) {
    south = point.latitude < south ? point.latitude : south;
    north = point.latitude > north ? point.latitude : north;
    west = point.longitude < west ? point.longitude : west;
    east = point.longitude > east ? point.longitude : east;
  }
  if (south == north) {
    south -= 0.0001;
    north += 0.0001;
  }
  if (west == east) {
    west -= 0.0001;
    east += 0.0001;
  }
  return _RouteBounds(south: south, north: north, west: west, east: east);
}

gmap.LatLngBounds _googleBoundsFor(List<MapCoordinate> points) {
  final bounds = _boundsFor(points);
  return gmap.LatLngBounds(
    southwest: gmap.LatLng(bounds.south, bounds.west),
    northeast: gmap.LatLng(bounds.north, bounds.east),
  );
}

amap.LatLngBounds _appleBoundsFor(List<MapCoordinate> points) {
  final bounds = _boundsFor(points);
  return amap.LatLngBounds(
    southwest: amap.LatLng(bounds.south, bounds.west),
    northeast: amap.LatLng(bounds.north, bounds.east),
  );
}

class _RouteBounds {
  const _RouteBounds({
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });

  final double south;
  final double north;
  final double west;
  final double east;
}

extension on MapCoordinate {
  gmap.LatLng toGoogleLatLng() => gmap.LatLng(latitude, longitude);
  amap.LatLng toAppleLatLng() => amap.LatLng(latitude, longitude);
}

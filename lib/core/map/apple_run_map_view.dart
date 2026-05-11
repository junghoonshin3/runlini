import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amap;
import 'package:flutter/material.dart';
import 'package:runlini/core/map/apple_map_coordinate_adapter.dart';
import 'package:runlini/core/map/apple_run_map_layers.dart';
import 'package:runlini/core/map/apple_run_marker_icons.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';

class AppleRunMapView extends StatefulWidget {
  const AppleRunMapView({
    super.key,
    required this.mapCenter,
    this.runnerMarkerPoint,
    this.ghostMarkerPoint,
    this.recenterTargetPoint,
    required this.currentRunnerPolylinePoints,
    required this.currentRunnerPolylineSegments,
    required this.ghostPolylinePoints,
    required this.ghostPolylineSegments,
    this.ghostRouteEndpointMarkers = const <MapRouteEndpointMarker>[],
    required this.recenterTick,
  });

  final MapCoordinate mapCenter;
  final MapCoordinate? runnerMarkerPoint;
  final MapCoordinate? ghostMarkerPoint;
  final MapCoordinate? recenterTargetPoint;
  final List<MapCoordinate> currentRunnerPolylinePoints;
  final List<MapPolylineSegment> currentRunnerPolylineSegments;
  final List<MapCoordinate> ghostPolylinePoints;
  final List<MapPolylineSegment> ghostPolylineSegments;
  final List<MapRouteEndpointMarker> ghostRouteEndpointMarkers;
  final int recenterTick;

  @override
  State<AppleRunMapView> createState() => _AppleRunMapViewState();
}

class _AppleRunMapViewState extends State<AppleRunMapView> {
  static const double _zoomLevel = 16.5;

  amap.AppleMapController? _mapController;
  amap.BitmapDescriptor? _ghostMarkerIcon;
  Map<MapRouteEndpointRole, amap.BitmapDescriptor>? _routeEndpointMarkerIcons;
  double? _ghostMarkerDevicePixelRatio;
  double? _routeEndpointMarkerDevicePixelRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final devicePixelRatio =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    if (_ghostMarkerIcon == null ||
        _ghostMarkerDevicePixelRatio != devicePixelRatio) {
      _loadGhostMarkerIcon(devicePixelRatio);
    }
    if (_routeEndpointMarkerIcons == null ||
        _routeEndpointMarkerDevicePixelRatio != devicePixelRatio) {
      _loadRouteEndpointMarkerIcons(devicePixelRatio);
    }
  }

  @override
  void didUpdateWidget(covariant AppleRunMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldFitGhostPolyline =
        widget.currentRunnerPolylinePoints.isEmpty &&
        widget.ghostPolylinePoints.isNotEmpty &&
        oldWidget.ghostPolylinePoints != widget.ghostPolylinePoints;
    if (shouldFitGhostPolyline) {
      _scheduleFitGhostPolyline();
      return;
    }

    final shouldRecenter = oldWidget.recenterTick != widget.recenterTick;
    final shouldFollowMapCenter = oldWidget.mapCenter != widget.mapCenter;
    if (!shouldRecenter && !shouldFollowMapCenter) {
      return;
    }

    final target = shouldRecenter
        ? widget.recenterTargetPoint
        : widget.mapCenter;
    if (target == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapController = _mapController;
      if (!mounted || mapController == null) {
        return;
      }

      mapController.animateCamera(
        amap.CameraUpdate.newLatLngZoom(target.toAppleLatLng(), _zoomLevel),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return amap.AppleMap(
      key: const Key('run-map'),
      initialCameraPosition: amap.CameraPosition(
        target: widget.mapCenter.toAppleLatLng(),
        zoom: _zoomLevel,
      ),
      onMapCreated: (amap.AppleMapController controller) {
        _mapController = controller;
        if (widget.currentRunnerPolylinePoints.isEmpty &&
            widget.ghostPolylinePoints.isNotEmpty) {
          _scheduleFitGhostPolyline();
        }
      },
      mapType: amap.MapType.standard,
      compassEnabled: false,
      trafficEnabled: false,
      pitchGesturesEnabled: false,
      annotations: <amap.Annotation>{
        ...appleRouteEndpointAnnotations(
          markers: widget.ghostRouteEndpointMarkers,
          icons: _routeEndpointMarkerIcons,
        ),
        if (widget.ghostMarkerPoint != null && _ghostMarkerIcon != null)
          amap.Annotation(
            annotationId: amap.AnnotationId('ghost-marker'),
            position: widget.ghostMarkerPoint!.toAppleLatLng(),
            anchor: const Offset(0.5, 0.5),
            icon: _ghostMarkerIcon!,
            zIndex: 2,
          ),
        if (widget.runnerMarkerPoint != null)
          amap.Annotation(
            annotationId: amap.AnnotationId('runner-marker'),
            position: widget.runnerMarkerPoint!.toAppleLatLng(),
            anchor: const Offset(0.5, 1.0),
            zIndex: 3,
          ),
      },
      polylines: <amap.Polyline>{
        ...appleGhostPolylines(
          points: widget.ghostPolylinePoints,
          segments: widget.ghostPolylineSegments,
        ),
        ...appleRunnerPolylines(
          points: widget.currentRunnerPolylinePoints,
          segments: widget.currentRunnerPolylineSegments,
        ),
      },
    );
  }

  void _scheduleFitGhostPolyline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapController = _mapController;
      if (!mounted ||
          mapController == null ||
          widget.ghostPolylinePoints.isEmpty) {
        return;
      }

      final bounds = appleBoundsFor(widget.ghostPolylinePoints);
      final hasSinglePointBounds =
          bounds.southwest.latitude == bounds.northeast.latitude &&
          bounds.southwest.longitude == bounds.northeast.longitude;

      if (hasSinglePointBounds) {
        mapController.animateCamera(
          amap.CameraUpdate.newLatLngZoom(
            widget.ghostPolylinePoints.first.toAppleLatLng(),
            _zoomLevel,
          ),
        );
        return;
      }

      mapController.animateCamera(
        amap.CameraUpdate.newLatLngBounds(bounds, 64),
      );
    });
  }

  Future<void> _loadGhostMarkerIcon(double devicePixelRatio) async {
    final amap.BitmapDescriptor icon = await AppleRunMarkerIcons.ghost(
      devicePixelRatio: devicePixelRatio,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _ghostMarkerIcon = icon;
      _ghostMarkerDevicePixelRatio = devicePixelRatio;
    });
  }

  Future<void> _loadRouteEndpointMarkerIcons(double devicePixelRatio) async {
    final icons = await AppleRunMarkerIcons.routeEndpoints(
      devicePixelRatio: devicePixelRatio,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _routeEndpointMarkerIcons = icons;
      _routeEndpointMarkerDevicePixelRatio = devicePixelRatio;
    });
  }
}

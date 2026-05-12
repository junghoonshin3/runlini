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
    this.recordRaceMarkerPoint,
    this.recenterTargetPoint,
    required this.currentRunnerPolylinePoints,
    required this.currentRunnerPolylineSegments,
    required this.recordRacePolylinePoints,
    required this.recordRacePolylineSegments,
    this.recordRaceRouteEndpointMarkers = const <MapRouteEndpointMarker>[],
    required this.recenterTick,
  });

  final MapCoordinate mapCenter;
  final MapCoordinate? runnerMarkerPoint;
  final MapCoordinate? recordRaceMarkerPoint;
  final MapCoordinate? recenterTargetPoint;
  final List<MapCoordinate> currentRunnerPolylinePoints;
  final List<MapPolylineSegment> currentRunnerPolylineSegments;
  final List<MapCoordinate> recordRacePolylinePoints;
  final List<MapPolylineSegment> recordRacePolylineSegments;
  final List<MapRouteEndpointMarker> recordRaceRouteEndpointMarkers;
  final int recenterTick;

  @override
  State<AppleRunMapView> createState() => _AppleRunMapViewState();
}

class _AppleRunMapViewState extends State<AppleRunMapView> {
  static const double _zoomLevel = 16.5;

  amap.AppleMapController? _mapController;
  amap.BitmapDescriptor? _recordRaceMarkerIcon;
  Map<MapRouteEndpointRole, amap.BitmapDescriptor>? _routeEndpointMarkerIcons;
  double? _recordRaceMarkerDevicePixelRatio;
  double? _routeEndpointMarkerDevicePixelRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final devicePixelRatio =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    if (_recordRaceMarkerIcon == null ||
        _recordRaceMarkerDevicePixelRatio != devicePixelRatio) {
      _loadRecordRaceMarkerIcon(devicePixelRatio);
    }
    if (_routeEndpointMarkerIcons == null ||
        _routeEndpointMarkerDevicePixelRatio != devicePixelRatio) {
      _loadRouteEndpointMarkerIcons(devicePixelRatio);
    }
  }

  @override
  void didUpdateWidget(covariant AppleRunMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldFitRecordRacePolyline =
        widget.currentRunnerPolylinePoints.isEmpty &&
        widget.recordRacePolylinePoints.isNotEmpty &&
        oldWidget.recordRacePolylinePoints != widget.recordRacePolylinePoints;
    if (shouldFitRecordRacePolyline) {
      _scheduleFitRecordRacePolyline();
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
            widget.recordRacePolylinePoints.isNotEmpty) {
          _scheduleFitRecordRacePolyline();
        }
      },
      mapType: amap.MapType.standard,
      compassEnabled: false,
      trafficEnabled: false,
      pitchGesturesEnabled: false,
      annotations: <amap.Annotation>{
        ...appleRouteEndpointAnnotations(
          markers: widget.recordRaceRouteEndpointMarkers,
          icons: _routeEndpointMarkerIcons,
        ),
        if (widget.recordRaceMarkerPoint != null &&
            _recordRaceMarkerIcon != null)
          amap.Annotation(
            annotationId: amap.AnnotationId('record-race-marker'),
            position: widget.recordRaceMarkerPoint!.toAppleLatLng(),
            anchor: const Offset(0.5, 0.5),
            icon: _recordRaceMarkerIcon!,
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
        ...appleRecordRacePolylines(
          points: widget.recordRacePolylinePoints,
          segments: widget.recordRacePolylineSegments,
        ),
        ...appleRunnerPolylines(
          points: widget.currentRunnerPolylinePoints,
          segments: widget.currentRunnerPolylineSegments,
        ),
      },
    );
  }

  void _scheduleFitRecordRacePolyline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapController = _mapController;
      if (!mounted ||
          mapController == null ||
          widget.recordRacePolylinePoints.isEmpty) {
        return;
      }

      final bounds = appleBoundsFor(widget.recordRacePolylinePoints);
      final hasSinglePointBounds =
          bounds.southwest.latitude == bounds.northeast.latitude &&
          bounds.southwest.longitude == bounds.northeast.longitude;

      if (hasSinglePointBounds) {
        mapController.animateCamera(
          amap.CameraUpdate.newLatLngZoom(
            widget.recordRacePolylinePoints.first.toAppleLatLng(),
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

  Future<void> _loadRecordRaceMarkerIcon(double devicePixelRatio) async {
    final amap.BitmapDescriptor icon = await AppleRunMarkerIcons.recordRace(
      devicePixelRatio: devicePixelRatio,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _recordRaceMarkerIcon = icon;
      _recordRaceMarkerDevicePixelRatio = devicePixelRatio;
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

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:runlini/core/map/google_map_coordinate_adapter.dart';
import 'package:runlini/core/map/google_run_map_layers.dart';
import 'package:runlini/core/map/google_run_marker_icons.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';

class GoogleRunMapView extends StatefulWidget {
  const GoogleRunMapView({
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
  State<GoogleRunMapView> createState() => _GoogleRunMapViewState();
}

class _GoogleRunMapViewState extends State<GoogleRunMapView> {
  static const double _zoomLevel = 16.5;

  gmap.GoogleMapController? _mapController;
  gmap.BitmapDescriptor? _runnerMarkerIcon;
  gmap.BitmapDescriptor? _ghostMarkerIcon;
  Map<MapRouteEndpointRole, gmap.BitmapDescriptor>? _routeEndpointMarkerIcons;
  double? _runnerMarkerDevicePixelRatio;
  double? _ghostMarkerDevicePixelRatio;
  double? _routeEndpointMarkerDevicePixelRatio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final devicePixelRatio =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    if (_runnerMarkerIcon == null ||
        _runnerMarkerDevicePixelRatio != devicePixelRatio) {
      _loadRunnerMarkerIcon(devicePixelRatio);
    }
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
  void didUpdateWidget(covariant GoogleRunMapView oldWidget) {
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
        gmap.CameraUpdate.newLatLngZoom(target.toGoogleLatLng(), _zoomLevel),
      );
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return gmap.GoogleMap(
      key: const Key('run-map'),
      initialCameraPosition: gmap.CameraPosition(
        target: widget.mapCenter.toGoogleLatLng(),
        zoom: _zoomLevel,
      ),
      onMapCreated: (gmap.GoogleMapController controller) {
        _mapController = controller;
        if (widget.currentRunnerPolylinePoints.isEmpty &&
            widget.ghostPolylinePoints.isNotEmpty) {
          _scheduleFitGhostPolyline();
        }
      },
      mapType: gmap.MapType.normal,
      compassEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      trafficEnabled: false,
      polylines: <gmap.Polyline>{
        ...googleGhostPolylines(
          points: widget.ghostPolylinePoints,
          segments: widget.ghostPolylineSegments,
        ),
        ...googleRunnerPolylines(
          points: widget.currentRunnerPolylinePoints,
          segments: widget.currentRunnerPolylineSegments,
        ),
      },
      markers: <gmap.Marker>{
        ...googleRouteEndpointMarkers(
          markers: widget.ghostRouteEndpointMarkers,
          icons: _routeEndpointMarkerIcons,
        ),
        if (widget.ghostMarkerPoint != null && _ghostMarkerIcon != null)
          gmap.Marker(
            markerId: const gmap.MarkerId('ghost-marker'),
            position: widget.ghostMarkerPoint!.toGoogleLatLng(),
            anchor: const Offset(0.5, 0.5),
            icon: _ghostMarkerIcon!,
            zIndexInt: 2,
          ),
        if (widget.runnerMarkerPoint != null && _runnerMarkerIcon != null)
          gmap.Marker(
            markerId: const gmap.MarkerId('runner-marker'),
            position: widget.runnerMarkerPoint!.toGoogleLatLng(),
            anchor: const Offset(0.5, 0.5),
            icon: _runnerMarkerIcon!,
            zIndexInt: 3,
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

      final bounds = googleBoundsFor(widget.ghostPolylinePoints);
      final hasSinglePointBounds =
          bounds.southwest.latitude == bounds.northeast.latitude &&
          bounds.southwest.longitude == bounds.northeast.longitude;

      if (hasSinglePointBounds) {
        mapController.animateCamera(
          gmap.CameraUpdate.newLatLngZoom(
            widget.ghostPolylinePoints.first.toGoogleLatLng(),
            _zoomLevel,
          ),
        );
        return;
      }

      mapController.animateCamera(
        gmap.CameraUpdate.newLatLngBounds(bounds, 64),
      );
    });
  }

  Future<void> _loadRunnerMarkerIcon(double devicePixelRatio) async {
    final gmap.BitmapDescriptor icon = await GoogleRunMarkerIcons.runner(
      devicePixelRatio: devicePixelRatio,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _runnerMarkerIcon = icon;
      _runnerMarkerDevicePixelRatio = devicePixelRatio;
    });
  }

  Future<void> _loadGhostMarkerIcon(double devicePixelRatio) async {
    final gmap.BitmapDescriptor icon = await GoogleRunMarkerIcons.ghost(
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
    final icons = await GoogleRunMarkerIcons.routeEndpoints(
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

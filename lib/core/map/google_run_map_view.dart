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
  State<GoogleRunMapView> createState() => _GoogleRunMapViewState();
}

class _GoogleRunMapViewState extends State<GoogleRunMapView> {
  static const double _zoomLevel = 16.5;

  gmap.GoogleMapController? _mapController;
  gmap.BitmapDescriptor? _runnerMarkerIcon;
  gmap.BitmapDescriptor? _recordRaceMarkerIcon;
  Map<MapRouteEndpointRole, gmap.BitmapDescriptor>? _routeEndpointMarkerIcons;
  double? _runnerMarkerDevicePixelRatio;
  double? _recordRaceMarkerDevicePixelRatio;
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
  void didUpdateWidget(covariant GoogleRunMapView oldWidget) {
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
            widget.recordRacePolylinePoints.isNotEmpty) {
          _scheduleFitRecordRacePolyline();
        }
      },
      mapType: gmap.MapType.normal,
      compassEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      trafficEnabled: false,
      polylines: <gmap.Polyline>{
        ...googleRecordRacePolylines(
          points: widget.recordRacePolylinePoints,
          segments: widget.recordRacePolylineSegments,
        ),
        ...googleRunnerPolylines(
          points: widget.currentRunnerPolylinePoints,
          segments: widget.currentRunnerPolylineSegments,
        ),
      },
      markers: <gmap.Marker>{
        ...googleRouteEndpointMarkers(
          markers: widget.recordRaceRouteEndpointMarkers,
          icons: _routeEndpointMarkerIcons,
        ),
        if (widget.recordRaceMarkerPoint != null &&
            _recordRaceMarkerIcon != null)
          gmap.Marker(
            markerId: const gmap.MarkerId('record-race-marker'),
            position: widget.recordRaceMarkerPoint!.toGoogleLatLng(),
            anchor: const Offset(0.5, 0.5),
            icon: _recordRaceMarkerIcon!,
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

  void _scheduleFitRecordRacePolyline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapController = _mapController;
      if (!mounted ||
          mapController == null ||
          widget.recordRacePolylinePoints.isEmpty) {
        return;
      }

      final bounds = googleBoundsFor(widget.recordRacePolylinePoints);
      final hasSinglePointBounds =
          bounds.southwest.latitude == bounds.northeast.latitude &&
          bounds.southwest.longitude == bounds.northeast.longitude;

      if (hasSinglePointBounds) {
        mapController.animateCamera(
          gmap.CameraUpdate.newLatLngZoom(
            widget.recordRacePolylinePoints.first.toGoogleLatLng(),
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

  Future<void> _loadRecordRaceMarkerIcon(double devicePixelRatio) async {
    final gmap.BitmapDescriptor icon = await GoogleRunMarkerIcons.recordRace(
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

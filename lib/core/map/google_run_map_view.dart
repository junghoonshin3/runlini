import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/google_map_coordinate_adapter.dart';
import 'package:runlini/core/map/google_run_marker_icons.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';

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
  final int recenterTick;

  @override
  State<GoogleRunMapView> createState() => _GoogleRunMapViewState();
}

class _GoogleRunMapViewState extends State<GoogleRunMapView> {
  static const double _zoomLevel = 16.5;

  gmap.GoogleMapController? _mapController;
  gmap.BitmapDescriptor? _runnerMarkerIcon;
  gmap.BitmapDescriptor? _ghostMarkerIcon;
  double? _runnerMarkerDevicePixelRatio;
  double? _ghostMarkerDevicePixelRatio;

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
      polylines: <gmap.Polyline>{..._ghostPolylines(), ..._runnerPolylines()},
      markers: <gmap.Marker>{
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

  Set<gmap.Polyline> _runnerPolylines() {
    final segments = widget.currentRunnerPolylineSegments.isEmpty
        ? <MapPolylineSegment>[
            if (widget.currentRunnerPolylinePoints.length >= 2)
              MapPolylineSegment(
                points: widget.currentRunnerPolylinePoints,
                color: AppColors.voltGreen,
              ),
          ]
        : widget.currentRunnerPolylineSegments;
    return <gmap.Polyline>{
      for (var index = 0; index < segments.length; index += 1)
        _runnerPolyline(
          id: 'runner-polyline-$index',
          points: segments[index].points,
          color: segments[index].color,
        ),
    };
  }

  gmap.Polyline _runnerPolyline({
    required String id,
    required List<MapCoordinate> points,
    required Color color,
  }) {
    return gmap.Polyline(
      polylineId: gmap.PolylineId(id),
      points: points
          .map((MapCoordinate point) => point.toGoogleLatLng())
          .toList(growable: false),
      color: color,
      width: 6,
      zIndex: 2,
    );
  }

  Set<gmap.Polyline> _ghostPolylines() {
    if (widget.ghostPolylineSegments.isEmpty &&
        widget.ghostPolylinePoints.isEmpty) {
      return const <gmap.Polyline>{};
    }

    if (widget.ghostPolylineSegments.isEmpty) {
      return <gmap.Polyline>{
        _ghostPolyline(
          id: 'ghost-polyline',
          points: widget.ghostPolylinePoints,
          color: AppColors.electricRed,
        ),
      };
    }

    return <gmap.Polyline>{
      for (
        var index = 0;
        index < widget.ghostPolylineSegments.length;
        index += 1
      )
        _ghostPolyline(
          id: 'ghost-polyline-$index',
          points: widget.ghostPolylineSegments[index].points,
          color: widget.ghostPolylineSegments[index].color,
        ),
    };
  }

  gmap.Polyline _ghostPolyline({
    required String id,
    required List<MapCoordinate> points,
    required Color color,
  }) {
    return gmap.Polyline(
      polylineId: gmap.PolylineId(id),
      startCap: gmap.Cap.roundCap,
      endCap: gmap.Cap.roundCap,
      jointType: gmap.JointType.round,
      points: points
          .map((MapCoordinate point) => point.toGoogleLatLng())
          .toList(growable: false),
      color: color,
      width: 10,
      zIndex: 1,
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
}

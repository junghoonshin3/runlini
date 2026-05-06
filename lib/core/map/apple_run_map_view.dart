import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amap;
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/map/apple_map_coordinate_adapter.dart';
import 'package:runlini/core/map/apple_run_marker_icons.dart';
import 'package:runlini/core/map/map_coordinate.dart';
import 'package:runlini/core/map/map_polyline_segment.dart';

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
  State<AppleRunMapView> createState() => _AppleRunMapViewState();
}

class _AppleRunMapViewState extends State<AppleRunMapView> {
  static const double _zoomLevel = 16.5;

  amap.AppleMapController? _mapController;
  amap.BitmapDescriptor? _ghostMarkerIcon;
  double? _ghostMarkerDevicePixelRatio;

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
      polylines: <amap.Polyline>{..._ghostPolylines(), ..._runnerPolylines()},
    );
  }

  Set<amap.Polyline> _runnerPolylines() {
    final segments = widget.currentRunnerPolylineSegments.isEmpty
        ? <MapPolylineSegment>[
            if (widget.currentRunnerPolylinePoints.length >= 2)
              MapPolylineSegment(
                points: widget.currentRunnerPolylinePoints,
                color: AppColors.voltGreen,
              ),
          ]
        : widget.currentRunnerPolylineSegments;
    return <amap.Polyline>{
      for (var index = 0; index < segments.length; index += 1)
        _runnerPolyline(
          id: 'runner-polyline-$index',
          points: segments[index].points,
          color: segments[index].color,
        ),
    };
  }

  amap.Polyline _runnerPolyline({
    required String id,
    required List<MapCoordinate> points,
    required Color color,
  }) {
    return amap.Polyline(
      polylineId: amap.PolylineId(id),
      points: points
          .map((MapCoordinate point) => point.toAppleLatLng())
          .toList(growable: false),
      color: color,
      width: 6,
      zIndex: 2,
    );
  }

  Set<amap.Polyline> _ghostPolylines() {
    if (widget.ghostPolylineSegments.isEmpty &&
        widget.ghostPolylinePoints.isEmpty) {
      return const <amap.Polyline>{};
    }

    if (widget.ghostPolylineSegments.isEmpty) {
      return <amap.Polyline>{
        _ghostPolyline(
          id: 'ghost-polyline',
          points: widget.ghostPolylinePoints,
          color: AppColors.electricRed,
        ),
      };
    }

    return <amap.Polyline>{
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

  amap.Polyline _ghostPolyline({
    required String id,
    required List<MapCoordinate> points,
    required Color color,
  }) {
    return amap.Polyline(
      polylineId: amap.PolylineId(id),
      polylineCap: amap.Cap.roundCap,
      jointType: amap.JointType.round,
      points: points
          .map((MapCoordinate point) => point.toAppleLatLng())
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
}

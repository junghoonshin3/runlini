// 지도 SDK용 코스 시작과 종료 깃발 asset bytes를 제공한다.
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:runlini/core/map/map_route_endpoint_marker.dart';

const double routeEndpointMarkerWidth = 44;
const double routeEndpointMarkerHeight = 52;

String routeEndpointAssetPath(MapRouteEndpointRole role) {
  return switch (role) {
    MapRouteEndpointRole.start => 'assets/map/flag_start.png',
    MapRouteEndpointRole.finish => 'assets/map/flag_finish.png',
    MapRouteEndpointRole.startFinish => 'assets/map/flag_sf.png',
  };
}

Future<Uint8List?> runRouteEndpointIconBytes({
  required MapRouteEndpointRole role,
  required double devicePixelRatio,
}) async {
  final imageWidth = (routeEndpointMarkerWidth * devicePixelRatio).round();
  final imageHeight = (routeEndpointMarkerHeight * devicePixelRatio).round();
  try {
    final data = await rootBundle.load(routeEndpointAssetPath(role));
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: imageWidth,
      targetHeight: imageHeight,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    codec.dispose();
    if (byteData == null) {
      return null;
    }
    return Uint8List.view(byteData.buffer);
  } catch (_) {
    return null;
  }
}

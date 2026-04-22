import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amap;
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

abstract final class AppleRunMarkerIcons {
  static const double _ghostMarkerSize = 30;

  static Future<amap.BitmapDescriptor> ghost({
    required double devicePixelRatio,
  }) async {
    final int imageSizePx = (_ghostMarkerSize * devicePixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(imageSizePx.toDouble(), imageSizePx.toDouble());
    final center = size.center(Offset.zero);

    canvas.drawCircle(
      center,
      size.width * 0.42,
      Paint()..color = AppColors.black.withValues(alpha: 0.72),
    );
    canvas.drawCircle(
      center,
      size.width * 0.34,
      Paint()..color = AppColors.chalk,
    );
    canvas.drawCircle(
      center,
      size.width * 0.23,
      Paint()..color = AppColors.electricRed,
    );

    final image = await recorder.endRecording().toImage(
      imageSizePx,
      imageSizePx,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      return amap.BitmapDescriptor.defaultAnnotationWithHue(0);
    }

    return amap.BitmapDescriptor.fromBytes(Uint8List.view(byteData.buffer));
  }
}

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:runlini/app/theme/app_colors.dart';

abstract final class GoogleRunMarkerIcons {
  static const double _runnerMarkerSize = 42;
  static const double _ghostMarkerSize = 30;
  static const Color _runnerMarkerBlue = Color(0xFF1A73E8);

  static Future<gmap.BitmapDescriptor> runner({
    required double devicePixelRatio,
  }) async {
    final int imageSizePx = (_runnerMarkerSize * devicePixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(imageSizePx.toDouble(), imageSizePx.toDouble());
    final center = size.center(Offset.zero);

    // Match the native Google Maps dot while keeping the route line readable.
    canvas.drawCircle(
      center,
      size.width * 0.42,
      Paint()..color = _runnerMarkerBlue.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      center,
      size.width * 0.24,
      Paint()..color = AppColors.chalk,
    );
    canvas.drawCircle(
      center,
      size.width * 0.18,
      Paint()..color = _runnerMarkerBlue,
    );
    canvas.drawCircle(
      center.translate(-size.width * 0.06, -size.width * 0.06),
      size.width * 0.05,
      Paint()..color = AppColors.chalk.withValues(alpha: 0.45),
    );

    final image = await recorder.endRecording().toImage(
      imageSizePx,
      imageSizePx,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      return gmap.BitmapDescriptor.defaultMarkerWithHue(
        gmap.BitmapDescriptor.hueAzure,
      );
    }

    return gmap.BitmapDescriptor.bytes(
      Uint8List.view(byteData.buffer),
      width: _runnerMarkerSize,
      height: _runnerMarkerSize,
    );
  }

  static Future<gmap.BitmapDescriptor> ghost({
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
      return gmap.BitmapDescriptor.defaultMarkerWithHue(
        gmap.BitmapDescriptor.hueRed,
      );
    }

    return gmap.BitmapDescriptor.bytes(
      Uint8List.view(byteData.buffer),
      width: _ghostMarkerSize,
      height: _ghostMarkerSize,
    );
  }
}

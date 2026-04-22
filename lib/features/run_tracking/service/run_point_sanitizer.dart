import 'package:latlong2/latlong.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

class RunPointSanitizer {
  const RunPointSanitizer({this.maxMetersPerSecond = 8.5});

  final double maxMetersPerSecond;

  static const Distance _distance = Distance();

  List<RunPoint> filter(List<RunPoint> points) {
    final accepted = <RunPoint>[];

    for (final point in points) {
      final previous = accepted.isEmpty ? null : accepted.last;
      if (_isAcceptable(previous: previous, next: point)) {
        accepted.add(point);
      }
    }

    return accepted;
  }

  bool _isAcceptable({required RunPoint? previous, required RunPoint next}) {
    if (previous == null) {
      return true;
    }

    final elapsedMs = next.timestampRelMs - previous.timestampRelMs;
    if (elapsedMs <= 0) {
      return false;
    }

    final distanceM = _distance.as(
      LengthUnit.Meter,
      LatLng(previous.latitude, previous.longitude),
      LatLng(next.latitude, next.longitude),
    );
    final speedMetersPerSecond = distanceM / (elapsedMs / 1000);
    return speedMetersPerSecond <= maxMetersPerSecond;
  }
}

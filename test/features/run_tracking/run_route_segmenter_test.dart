import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/service/run_route_segmenter.dart';
import 'package:runlini/features/run_tracking/types/run_point.dart';

void main() {
  const segmenter = RunRouteSegmenter();

  test('keeps normal continuous running transitions', () {
    final route = segmenter.segment([
      _point(latitude: 37.0, longitude: 127.0, timestampRelMs: 0),
      _point(latitude: 37.0, longitude: 127.001, timestampRelMs: 30000),
      _point(latitude: 37.0, longitude: 127.002, timestampRelMs: 60000),
    ]);

    expect(route.segments, hasLength(1));
    expect(route.segments.single, hasLength(3));
    expect(route.transitions, hasLength(2));
    expect(route.distanceM, closeTo(178, 8));
  });

  test('breaks a long GPS gap bridge instead of counting it', () {
    final route = segmenter.segment([
      _point(latitude: 37.0, longitude: 127.0, timestampRelMs: 0),
      _point(latitude: 37.0, longitude: 127.001, timestampRelMs: 30000),
      _point(latitude: 37.009, longitude: 127.001, timestampRelMs: 153000),
    ]);

    expect(route.segments, hasLength(2));
    expect(route.transitions, hasLength(1));
    expect(route.distanceM, closeTo(89, 6));
  });

  test('breaks observed 44 second 373 meter jump case', () {
    final route = segmenter.segment([
      _point(latitude: 37.514, longitude: 127.142, timestampRelMs: 0),
      _point(latitude: 37.516, longitude: 127.145, timestampRelMs: 44100),
    ]);

    expect(route.transitions, isEmpty);
    expect(route.distanceM, 0);
  });

  test('breaks explicit segment starts even when the bridge is plausible', () {
    final route = segmenter.segment([
      _point(latitude: 37.0, longitude: 127.0, timestampRelMs: 0),
      _point(
        latitude: 37.0,
        longitude: 127.0001,
        timestampRelMs: 10000,
        startsNewSegment: true,
      ),
      _point(latitude: 37.0, longitude: 127.0002, timestampRelMs: 20000),
    ]);

    expect(route.segments, hasLength(2));
    expect(route.transitions, hasLength(1));
    expect(route.distanceM, closeTo(8.9, 1));
  });

  test('skips poor accuracy points as segment breaks', () {
    final route = segmenter.segment([
      _point(latitude: 37.0, longitude: 127.0, timestampRelMs: 0),
      _point(
        latitude: 37.0,
        longitude: 127.001,
        timestampRelMs: 10000,
        horizontalAccuracyM: 80,
      ),
      _point(latitude: 37.0, longitude: 127.002, timestampRelMs: 20000),
    ]);

    expect(route.segments, hasLength(2));
    expect(route.transitions, isEmpty);
    expect(route.distanceM, 0);
  });
}

RunPoint _point({
  required double latitude,
  required double longitude,
  required int timestampRelMs,
  double? horizontalAccuracyM,
  bool startsNewSegment = false,
}) {
  return RunPoint(
    latitude: latitude,
    longitude: longitude,
    timestampRelMs: timestampRelMs,
    horizontalAccuracyM: horizontalAccuracyM,
    source: RunPointSource.deviceGps,
    startsNewSegment: startsNewSegment,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/location/run_pace_sample_sanitizer.dart';

void main() {
  const sanitizer = RunPaceSampleSanitizer();

  test('drops tiny positive GPS speed noise', () {
    expect(sanitizer.acceptedSpeedMps(0.08), isNull);
    expect(sanitizer.paceFromSpeedMps(0.08), isNull);
  });

  test('keeps normal running speed and derives pace', () {
    expect(sanitizer.acceptedSpeedMps(2.5), 2.5);
    expect(sanitizer.paceFromSpeedMps(2.5), 400);
  });

  test('filters pace samples outside running graph range', () {
    expect(sanitizer.isRenderablePace(119), isFalse);
    expect(sanitizer.isRenderablePace(120), isTrue);
    expect(sanitizer.isRenderablePace(1800), isTrue);
    expect(sanitizer.isRenderablePace(1801), isFalse);
  });
}

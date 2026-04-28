import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/formatters/run_display_formatters.dart';

void main() {
  test('formats distance, pace, and speed in miles', () {
    const settings = RunDisplaySettings(
      distanceUnit: RunDistanceUnit.mi,
      paceUnit: RunPaceUnit.minPerMi,
      speedUnit: RunSpeedUnit.mph,
    );

    expect(formatRunDistance(1609.344, settings), '1.0 mi');
    expect(formatRunPace(300, settings), '8:03 /mi');
    expect(paceUnitLabel(settings), 'min/mi');
    expect(formatRunSpeed(10, settings), '6.2 mph');
    expect(formatRunDistanceGap(42, settings), '0.03 mi');
    expect(splitDistanceMetersForDisplay(settings), 1609.344);
  });

  test('formats short distance gaps in meters for kilometer display', () {
    const settings = RunDisplaySettings();

    expect(formatRunDistanceGap(42, settings), '42 m');
    expect(paceUnitLabel(settings), 'min/km');
    expect(splitDistanceMetersForDisplay(settings), 1000);
  });
}

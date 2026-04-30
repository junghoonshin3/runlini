import 'package:flutter_test/flutter_test.dart';

import '../../tool/emulator_gps_route_model.dart';

void main() {
  test('parses wear debug injection option', () {
    final options = SimulatorOptions.parse(<String>[
      '--wear-debug-injection',
      '--device',
      'emulator-5554',
    ]);

    expect(options.wearDebugInjection, isTrue);
    expect(options.deviceId, 'emulator-5554');
  });

  test('wear debug injection args target Runlini receiver', () {
    final args = buildWearDebugInjectionArgs(
      deviceId: 'emulator-5554',
      coordinate: const Coordinate(latitude: 34.668446, longitude: 135.496953),
      elapsed: const Duration(seconds: 12),
      distanceM: 50,
      paceSecPerKm: 420,
    );

    expect(
      args,
      containsAll(<String>[
        '-s',
        'emulator-5554',
        'broadcast',
        '-p',
        'kr.sjh.runlini',
        '-a',
        wearDebugGpsAction,
        'lat',
        '34.6684460',
        'lng',
        '135.4969530',
        'elapsedMs',
        '12000',
        'distanceM',
        '50.000',
      ]),
    );
  });

  test('default simulator mode keeps geo fix path', () {
    final options = SimulatorOptions.parse(const <String>[]);

    expect(options.wearDebugInjection, isFalse);
  });
}

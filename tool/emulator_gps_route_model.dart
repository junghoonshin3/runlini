import 'dart:io';
import 'dart:math' as math;

const String defaultRoutePath =
    'assets/fixtures/osaka_namba_kanzakigawa_route.json';
const String defaultDeviceId = 'emulator-5554';
const double defaultPaceSecPerKm = 420;
const double defaultTimeScale = 6;
const Duration defaultInterval = Duration(seconds: 1);

class SimulatorOptions {
  const SimulatorOptions({
    required this.routePath,
    required this.deviceId,
    required this.adbPath,
    required this.paceSecPerKm,
    required this.timeScale,
    required this.interval,
    required this.maxUpdates,
    required this.dryRun,
    required this.wearDebugInjection,
    required this.showHelp,
  });

  final String routePath;
  final String deviceId;
  final String adbPath;
  final double paceSecPerKm;
  final double timeScale;
  final Duration interval;
  final int? maxUpdates;
  final bool dryRun;
  final bool wearDebugInjection;
  final bool showHelp;

  factory SimulatorOptions.parse(List<String> args) {
    var routePath = defaultRoutePath;
    var deviceId = defaultDeviceId;
    var adbPath = defaultAdbPath;
    var paceSecPerKm = defaultPaceSecPerKm;
    var timeScale = defaultTimeScale;
    var interval = defaultInterval;
    int? maxUpdates;
    var dryRun = false;
    var wearDebugInjection = false;
    var showHelp = false;

    for (var index = 0; index < args.length; index += 1) {
      final arg = args[index];
      switch (arg) {
        case '--help':
        case '-h':
          showHelp = true;
        case '--route':
          routePath = readValue(args, ++index, arg);
        case '--device':
          deviceId = readValue(args, ++index, arg);
        case '--adb':
          adbPath = readValue(args, ++index, arg);
        case '--pace-sec-per-km':
          paceSecPerKm = double.parse(readValue(args, ++index, arg));
        case '--time-scale':
          timeScale = double.parse(readValue(args, ++index, arg));
        case '--interval-ms':
          interval = Duration(
            milliseconds: int.parse(readValue(args, ++index, arg)),
          );
        case '--max-updates':
          maxUpdates = int.parse(readValue(args, ++index, arg));
        case '--dry-run':
          dryRun = true;
        case '--wear-debug-injection':
          wearDebugInjection = true;
        default:
          throw FormatException('Unknown option: $arg');
      }
    }

    if (paceSecPerKm <= 0) {
      throw const FormatException('--pace-sec-per-km must be positive.');
    }
    if (timeScale <= 0) {
      throw const FormatException('--time-scale must be positive.');
    }
    if (interval.inMilliseconds <= 0) {
      throw const FormatException('--interval-ms must be positive.');
    }
    if (maxUpdates != null && maxUpdates <= 0) {
      throw const FormatException('--max-updates must be positive.');
    }

    return SimulatorOptions(
      routePath: routePath,
      deviceId: deviceId,
      adbPath: adbPath,
      paceSecPerKm: paceSecPerKm,
      timeScale: timeScale,
      interval: interval,
      maxUpdates: maxUpdates,
      dryRun: dryRun,
      wearDebugInjection: wearDebugInjection,
      showHelp: showHelp,
    );
  }
}

class TimedRoute {
  const TimedRoute({
    required this.points,
    required this.cumulativeMeters,
    required this.duration,
  });

  final List<Coordinate> points;
  final List<double> cumulativeMeters;
  final Duration duration;

  factory TimedRoute.fromCoordinates(
    List<Coordinate> points, {
    required double paceSecPerKm,
  }) {
    final cumulativeMeters = <double>[0];
    for (var index = 1; index < points.length; index += 1) {
      cumulativeMeters.add(
        cumulativeMeters.last + points[index - 1].distanceTo(points[index]),
      );
    }
    final durationMs = (cumulativeMeters.last / 1000 * paceSecPerKm * 1000)
        .round();
    return TimedRoute(
      points: points,
      cumulativeMeters: cumulativeMeters,
      duration: Duration(milliseconds: durationMs),
    );
  }

  Coordinate positionAt(Duration elapsed) {
    if (elapsed <= Duration.zero) {
      return points.first;
    }
    if (elapsed >= duration) {
      return points.last;
    }

    final targetMeters =
        (elapsed.inMilliseconds / duration.inMilliseconds) *
        cumulativeMeters.last;
    for (var index = 1; index < cumulativeMeters.length; index += 1) {
      if (targetMeters > cumulativeMeters[index]) {
        continue;
      }

      final startMeters = cumulativeMeters[index - 1];
      final endMeters = cumulativeMeters[index];
      final segmentMeters = endMeters - startMeters;
      final ratio = segmentMeters <= 0
          ? 0.0
          : ((targetMeters - startMeters) / segmentMeters)
                .clamp(0.0, 1.0)
                .toDouble();
      return points[index - 1].lerp(points[index], ratio);
    }

    return points.last;
  }

  double distanceAt(Duration elapsed) {
    if (elapsed <= Duration.zero) {
      return 0;
    }
    if (elapsed >= duration) {
      return cumulativeMeters.last;
    }
    return (elapsed.inMilliseconds / duration.inMilliseconds) *
        cumulativeMeters.last;
  }
}

class Coordinate {
  const Coordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Coordinate lerp(Coordinate other, double ratio) {
    return Coordinate(
      latitude: latitude + ((other.latitude - latitude) * ratio),
      longitude: longitude + ((other.longitude - longitude) * ratio),
    );
  }

  double distanceTo(Coordinate other) {
    const earthRadiusM = 6371000.0;
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final deltaLat = (other.latitude - latitude) * math.pi / 180;
    final deltaLng = (other.longitude - longitude) * math.pi / 180;
    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }
}

String readValue(List<String> args, int index, String optionName) {
  if (index >= args.length) {
    throw FormatException('$optionName requires a value.');
  }
  return args[index];
}

String formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String get defaultAdbPath {
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    return 'adb';
  }
  return '$home/Library/Android/sdk/platform-tools/adb';
}

const String wearDebugGpsAction = 'kr.sjh.runlini.wear.debug.GPS_SAMPLE';

List<String> buildWearDebugInjectionArgs({
  required String deviceId,
  required Coordinate coordinate,
  required Duration elapsed,
  required double distanceM,
  required double paceSecPerKm,
  double accuracyM = 5,
  double elevationM = 0,
}) {
  final speedMps = 1000 / paceSecPerKm;
  return <String>[
    '-s',
    deviceId,
    'shell',
    'am',
    'broadcast',
    '-p',
    'kr.sjh.runlini',
    '-a',
    wearDebugGpsAction,
    '--ef',
    'lat',
    coordinate.latitude.toStringAsFixed(7),
    '--ef',
    'lng',
    coordinate.longitude.toStringAsFixed(7),
    '--el',
    'elapsedMs',
    elapsed.inMilliseconds.toString(),
    '--ef',
    'distanceM',
    distanceM.toStringAsFixed(3),
    '--ef',
    'speedMps',
    speedMps.toStringAsFixed(6),
    '--ef',
    'paceSecPerKm',
    paceSecPerKm.toStringAsFixed(3),
    '--ef',
    'accuracyM',
    accuracyM.toStringAsFixed(3),
    '--ef',
    'elevationM',
    elevationM.toStringAsFixed(3),
  ];
}

const String simulatorUsage = '''
Runlini emulator GPS route simulator.

Usage:
  dart run tool/emulator_gps_route_simulator.dart [options]

Options:
  --route <path>            Route JSON path.
  --device <id>             Emulator id. Default: emulator-5554
  --adb <path>              adb path. Default: ~/Library/Android/sdk/platform-tools/adb
  --pace-sec-per-km <sec>   Simulated running pace. Default: 420
  --time-scale <factor>     Wall-clock speed-up. Default: 6
  --interval-ms <ms>        GPS update interval. Default: 1000
  --max-updates <count>     Stop after this many emitted GPS updates.
  --dry-run                 Print coordinates without calling adb.
  --wear-debug-injection    Send debug-only Wear GPS samples by ADB broadcast.
  -h, --help                Show this help.
  dart run tool/emulator_gps_route_simulator.dart
  dart run tool/emulator_gps_route_simulator.dart --wear-debug-injection --time-scale 6
''';

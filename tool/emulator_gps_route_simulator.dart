import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'emulator_gps_route_model.dart';

Future<void> main(List<String> args) async {
  final options = SimulatorOptions.parse(args);
  if (options.showHelp) {
    stdout.writeln(simulatorUsage);
    return;
  }

  final coordinates = await _loadRouteCoordinates(options.routePath);
  if (coordinates.length < 2) {
    stderr.writeln('Route needs at least two coordinates.');
    exitCode = 64;
    return;
  }

  final route = TimedRoute.fromCoordinates(
    coordinates,
    paceSecPerKm: options.paceSecPerKm,
  );
  final simulatedDuration = Duration(
    milliseconds: (route.duration.inMilliseconds / options.timeScale).round(),
  );

  stdout.writeln(
    'Runlini emulator GPS simulator\n'
    'device=${options.deviceId}, points=${coordinates.length}, '
    'pace=${options.paceSecPerKm.toStringAsFixed(0)} sec/km, '
    'timeScale=${options.timeScale.toStringAsFixed(1)}x, '
    'mode=${options.wearDebugInjection ? 'wear-debug-injection' : 'geo-fix'}\n'
    'simulated route time=${formatDuration(route.duration)}, '
    'wall time=${formatDuration(simulatedDuration)}, '
    'interval=${options.interval.inMilliseconds}ms',
  );

  final stopwatch = Stopwatch()..start();
  var tick = 0;
  while (true) {
    final elapsed = Duration(
      milliseconds: (stopwatch.elapsedMilliseconds * options.timeScale).round(),
    );
    final coordinate = route.positionAt(elapsed);
    final distanceM = route.distanceAt(elapsed);
    if (options.dryRun) {
      if (options.wearDebugInjection) {
        stdout.writeln(
          'dry-run ${buildWearDebugInjectionArgs(deviceId: options.deviceId, coordinate: coordinate, elapsed: elapsed, distanceM: distanceM, paceSecPerKm: options.paceSecPerKm).join(' ')}',
        );
      } else {
        stdout.writeln(
          'dry-run ${formatDuration(elapsed)} '
          '${coordinate.longitude.toStringAsFixed(7)} '
          '${coordinate.latitude.toStringAsFixed(7)}',
        );
      }
    } else {
      await _sendLocation(
        options: options,
        coordinate: coordinate,
        elapsed: elapsed,
        distanceM: distanceM,
      );
      stdout.writeln(
        '${tick.toString().padLeft(3, '0')} '
        '${formatDuration(elapsed)} '
        'lng=${coordinate.longitude.toStringAsFixed(7)} '
        'lat=${coordinate.latitude.toStringAsFixed(7)}',
      );
    }

    if (elapsed >= route.duration) {
      break;
    }
    if (options.maxUpdates != null && tick + 1 >= options.maxUpdates!) {
      break;
    }

    tick += 1;
    await Future<void>.delayed(options.interval);
  }
}

Future<List<Coordinate>> _loadRouteCoordinates(String routePath) async {
  final rawJson = await File(routePath).readAsString();
  final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
  final routes = decoded['routes'] as List<dynamic>;
  final route = routes.first as Map<String, dynamic>;
  final polyline = route['polyline'] as Map<String, dynamic>;
  final lineString = polyline['geoJsonLinestring'] as Map<String, dynamic>;
  final coordinates = lineString['coordinates'] as List<dynamic>;
  return coordinates
      .map((dynamic rawCoordinate) {
        final pair = rawCoordinate as List<dynamic>;
        return Coordinate(
          latitude: (pair[1] as num).toDouble(),
          longitude: (pair[0] as num).toDouble(),
        );
      })
      .toList(growable: false);
}

Future<void> _sendLocation({
  required SimulatorOptions options,
  required Coordinate coordinate,
  required Duration elapsed,
  required double distanceM,
}) async {
  if (options.wearDebugInjection) {
    await _sendWearDebugInjection(
      options: options,
      coordinate: coordinate,
      elapsed: elapsed,
      distanceM: distanceM,
    );
    return;
  }

  final result = await Process.run(options.adbPath, <String>[
    '-s',
    options.deviceId,
    'emu',
    'geo',
    'fix',
    coordinate.longitude.toStringAsFixed(7),
    coordinate.latitude.toStringAsFixed(7),
  ]);

  if (result.exitCode == 0) {
    return;
  }

  stderr.writeln(result.stderr);
  stderr.writeln(result.stdout);
  throw StateError('adb geo fix failed with exit code ${result.exitCode}');
}

Future<void> _sendWearDebugInjection({
  required SimulatorOptions options,
  required Coordinate coordinate,
  required Duration elapsed,
  required double distanceM,
}) async {
  final result = await Process.run(
    options.adbPath,
    buildWearDebugInjectionArgs(
      deviceId: options.deviceId,
      coordinate: coordinate,
      elapsed: elapsed,
      distanceM: distanceM,
      paceSecPerKm: options.paceSecPerKm,
    ),
  );

  if (result.exitCode == 0) {
    return;
  }

  stderr.writeln(result.stderr);
  stderr.writeln(result.stdout);
  throw StateError(
    'Wear debug GPS injection failed with exit code ${result.exitCode}',
  );
}

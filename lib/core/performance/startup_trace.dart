import 'package:flutter/foundation.dart';

class StartupTrace {
  const StartupTrace._();

  static Future<T> measure<T>(String label, Future<T> Function() action) async {
    if (!kDebugMode && !kProfileMode) {
      return action();
    }
    final stopwatch = Stopwatch()..start();
    debugPrint('Runlini startup $label started');
    try {
      return await action();
    } finally {
      stopwatch.stop();
      debugPrint(
        'Runlini startup $label finished in '
        '${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }
}

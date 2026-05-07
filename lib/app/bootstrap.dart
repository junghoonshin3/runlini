import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/runlini_app.dart';
import 'package:runlini/core/crash/crash_reporting.dart';
import 'package:runlini/firebase_options.dart';

final bool _isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');

void bootstrap({CrashReporter? crashReporter}) {
  final reporter = crashReporter ?? FirebaseCrashReporter();
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final firebaseOptions =
          !_isFlutterTest && (Platform.isAndroid || Platform.isIOS)
          ? DefaultFirebaseOptions.currentPlatform
          : null;
      await reporter.install(
        collectionEnabled: !_isFlutterTest,
        options: firebaseOptions,
      );
      runApp(const ProviderScope(child: RunliniApp()));
    },
    (error, stackTrace) {
      unawaited(reporter.recordError(error, stackTrace, fatal: true));
    },
  );
}

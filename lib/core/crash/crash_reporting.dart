import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class CrashReporter {
  Future<void> install({
    required bool collectionEnabled,
    FirebaseOptions? options,
  });

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
  });
}

class NoOpCrashReporter implements CrashReporter {
  const NoOpCrashReporter();

  @override
  Future<void> install({
    required bool collectionEnabled,
    FirebaseOptions? options,
  }) async {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
  }) async {}
}

class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashlytics? _crashlytics;

  @override
  Future<void> install({
    required bool collectionEnabled,
    FirebaseOptions? options,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    try {
      await Firebase.initializeApp(options: options);
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(collectionEnabled);
      _crashlytics = crashlytics;

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(crashlytics.recordFlutterFatalError(details));
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(recordError(error, stackTrace, fatal: true));
        return true;
      };
    } catch (error) {
      debugPrint('Runlini Crashlytics disabled: $error');
      _crashlytics = null;
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    required bool fatal,
  }) async {
    final crashlytics = _crashlytics;
    if (crashlytics == null) {
      return;
    }
    try {
      await crashlytics.recordError(error, stackTrace, fatal: fatal);
    } catch (_) {
      return;
    }
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

const String runVoiceCueLanguage = 'ko-KR';
const double runVoiceCueSpeechRate = 0.42;

abstract class RunVoiceCueClient {
  Future<bool> speak(String text, {required double volume});

  Future<void> stop();
}

class NoOpRunVoiceCueClient implements RunVoiceCueClient {
  const NoOpRunVoiceCueClient();

  @override
  Future<bool> speak(String text, {required double volume}) async => false;

  @override
  Future<void> stop() async {}
}

class FlutterTtsRunVoiceCueClient implements RunVoiceCueClient {
  FlutterTtsRunVoiceCueClient({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;
  bool _configured = false;

  @override
  Future<bool> speak(String text, {required double volume}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }
    try {
      await _configureIfNeeded();
      await _flutterTts.setVolume(volume.clamp(0, 1).toDouble());
      final Object? result;
      if (Platform.isAndroid) {
        result = await _flutterTts.speak(trimmed, focus: true);
      } else {
        result = await _flutterTts.speak(trimmed);
      }
      if (result is num && result == 0) {
        debugPrint('Runlini voice cue dropped: $trimmed');
        return false;
      }
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      debugPrint('Runlini voice cue skipped: $error');
      return false;
    } catch (error) {
      debugPrint('Runlini voice cue skipped: $error');
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<void> _configureIfNeeded() async {
    if (_configured) {
      return;
    }
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage(runVoiceCueLanguage);
    await _flutterTts.setSpeechRate(runVoiceCueSpeechRate);
    await _flutterTts.setPitch(1.0);
    if (Platform.isAndroid) {
      await _flutterTts.setAudioAttributesForNavigation();
    }
    if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        <IosTextToSpeechAudioCategoryOptions>[
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
    _configured = true;
  }
}

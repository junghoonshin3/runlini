// 러닝 음성 안내 dispatcher의 우선순위 발화 정책을 검증한다.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:runlini/core/voice/run_voice_cue_client.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_dispatcher.dart';

void main() {
  test(
    'urgent cue interrupts the current speech and starts immediately',
    () async {
      final client = _BlockingRunVoiceCueClient();
      final dispatcher = RunVoiceCueDispatcher();

      dispatcher.enqueue([
        _cue('1킬로미터', priority: RunVoiceCuePriority.low),
      ], client);
      await _flushAsyncWork();

      dispatcher.enqueue([
        _cue('경로를 벗어났어요', priority: RunVoiceCuePriority.urgent),
      ], client);
      await _flushAsyncWork();

      expect(client.stopCount, 1);
      expect(client.spoken, <String>['1킬로미터', '경로를 벗어났어요']);

      client.completeAll(true);
      await _flushAsyncWork();
    },
  );

  test('non urgent cue does not interrupt the current speech', () async {
    final client = _BlockingRunVoiceCueClient();
    final dispatcher = RunVoiceCueDispatcher();

    dispatcher.enqueue([
      _cue('1킬로미터', priority: RunVoiceCuePriority.low),
    ], client);
    await _flushAsyncWork();

    dispatcher.enqueue([
      _cue('질주 2/8', priority: RunVoiceCuePriority.normal),
    ], client);
    await _flushAsyncWork();

    expect(client.stopCount, 0);
    expect(client.spoken, <String>['1킬로미터']);

    client.completeAll(true);
    await _flushAsyncWork();
  });

  test('urgent cue is retried once when the TTS client rejects it', () async {
    final client = _ScriptedRunVoiceCueClient(<bool>[false, true]);
    final dispatcher = RunVoiceCueDispatcher();

    dispatcher.enqueue([
      _cue('경로를 벗어났어요', priority: RunVoiceCuePriority.urgent),
    ], client);
    await _flushAsyncWork();

    expect(client.stopCount, 1);
    expect(client.spoken, <String>['경로를 벗어났어요', '경로를 벗어났어요']);
  });
}

RunVoiceCue _cue(String text, {required RunVoiceCuePriority priority}) {
  return RunVoiceCue(text: text, volume: 0.8, priority: priority);
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _BlockingRunVoiceCueClient implements RunVoiceCueClient {
  final List<String> spoken = <String>[];
  final List<double> volumes = <double>[];
  final List<Completer<bool>> _pending = <Completer<bool>>[];
  var stopCount = 0;

  @override
  Future<bool> speak(String text, {required double volume}) {
    spoken.add(text);
    volumes.add(volume);
    final completer = Completer<bool>();
    _pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    completeNext(false);
  }

  void completeNext(bool accepted) {
    if (_pending.isEmpty) {
      return;
    }
    final completer = _pending.removeAt(0);
    if (!completer.isCompleted) {
      completer.complete(accepted);
    }
  }

  void completeAll(bool accepted) {
    while (_pending.isNotEmpty) {
      completeNext(accepted);
    }
  }
}

class _ScriptedRunVoiceCueClient implements RunVoiceCueClient {
  _ScriptedRunVoiceCueClient(List<bool> results) : _results = results;

  final List<bool> _results;
  final List<String> spoken = <String>[];
  var stopCount = 0;

  @override
  Future<bool> speak(String text, {required double volume}) async {
    spoken.add(text);
    if (_results.isEmpty) {
      return true;
    }
    return _results.removeAt(0);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}

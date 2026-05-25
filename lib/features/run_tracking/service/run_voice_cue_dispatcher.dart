// 러닝 음성 안내를 우선순위에 따라 직렬 발화한다.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:runlini/core/voice/run_voice_cue_client.dart';
import 'package:runlini/features/run_tracking/service/run_voice_cue_coordinator.dart';

class RunVoiceCueDispatcher {
  var _generation = 0;
  var _speaking = false;

  void enqueue(List<RunVoiceCue> cues, RunVoiceCueClient client) {
    if (cues.isEmpty) {
      return;
    }
    final cueBatch = List<RunVoiceCue>.unmodifiable(cues);
    if (_speaking) {
      if (_highestPriority(cueBatch) == RunVoiceCuePriority.urgent) {
        _generation += 1;
        unawaited(_interruptAndSpeak(cueBatch, client, _generation));
        return;
      }
      debugPrint(
        'Runlini voice cue skipped while busy: ${_cueSummary(cueBatch)}',
      );
      return;
    }

    _generation += 1;
    unawaited(_speakBatch(cueBatch, client, _generation));
  }

  Future<void> stop(RunVoiceCueClient client) async {
    _generation += 1;
    _speaking = false;
    await _stopClient(client);
  }

  Future<void> _interruptAndSpeak(
    List<RunVoiceCue> cues,
    RunVoiceCueClient client,
    int generation,
  ) async {
    await _stopClient(client);
    if (generation != _generation) {
      return;
    }
    await _speakBatch(cues, client, generation);
  }

  Future<void> _speakBatch(
    List<RunVoiceCue> cues,
    RunVoiceCueClient client,
    int generation,
  ) async {
    _speaking = true;
    try {
      for (final cue in cues) {
        if (generation != _generation) {
          return;
        }
        final accepted = await _speakCue(cue, client, generation);
        if (generation != _generation) {
          return;
        }
        if (!accepted) {
          debugPrint('Runlini voice cue was not accepted: ${cue.text}');
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Runlini voice cue failed: $error');
      debugPrint('$stackTrace');
    } finally {
      if (generation == _generation) {
        _speaking = false;
      }
    }
  }

  Future<bool> _speakCue(
    RunVoiceCue cue,
    RunVoiceCueClient client,
    int generation,
  ) async {
    final accepted = await client.speak(cue.text, volume: cue.volume);
    if (accepted ||
        cue.priority != RunVoiceCuePriority.urgent ||
        generation != _generation) {
      return accepted;
    }

    await _stopClient(client);
    if (generation != _generation) {
      return false;
    }
    return client.speak(cue.text, volume: cue.volume);
  }

  Future<void> _stopClient(RunVoiceCueClient client) async {
    try {
      await client.stop();
    } catch (error, stackTrace) {
      debugPrint('Runlini voice cue stop failed: $error');
      debugPrint('$stackTrace');
    }
  }

  RunVoiceCuePriority _highestPriority(List<RunVoiceCue> cues) {
    var priority = RunVoiceCuePriority.low;
    for (final cue in cues) {
      if (cue.priority.index > priority.index) {
        priority = cue.priority;
      }
    }
    return priority;
  }

  String _cueSummary(List<RunVoiceCue> cues) {
    return cues.map((cue) => cue.text).join(' / ');
  }
}

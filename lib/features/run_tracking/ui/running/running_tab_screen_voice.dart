part of 'running_tab_screen.dart';

extension _RunningTabScreenVoice on _RunningTabScreenState {
  void _listenForRunVoiceCues() {
    ref.listen(runVoiceCueSnapshotProvider, (previous, next) {
      final cues = _voiceCueCoordinator.cuesFor(next);
      if (cues.isEmpty) {
        return;
      }
      unawaited(_speakRunVoiceCues(cues));
    });
  }

  Future<void> _speakRunVoiceCues(List<RunVoiceCue> cues) async {
    final client = ref.read(runVoiceCueClientProvider);
    try {
      for (final cue in cues) {
        await client.speak(cue.text, volume: cue.volume);
      }
    } catch (error, stackTrace) {
      debugPrint('Runlini voice cue failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

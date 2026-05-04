part of 'runlini_home_screen.dart';

extension on _RunliniHomeScreenState {
  void _scheduleHealthSync() {
    if (_healthSyncScheduled) {
      return;
    }
    _healthSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(healthSyncControllerProvider.notifier).syncIfAuthorized();
    });
  }

  void _scheduleWearDraftSync() {
    if (_wearDraftSyncScheduled) {
      return;
    }
    _wearDraftSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncWearDrafts();
    });
  }

  void _scheduleWearGhostConfigSync() {
    if (_wearGhostConfigSyncScheduled) {
      return;
    }
    _wearGhostConfigSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncRecentWatchGhostConfigs();
    });
  }

  void _scheduleWearIntervalSync() {
    if (_wearIntervalSyncScheduled) {
      return;
    }
    _wearIntervalSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncWatchIntervalConfig();
      _syncWatchVoiceSettings();
    });
  }

  void _syncWearDrafts() {
    if (!mounted) {
      return;
    }
    ref.read(wearDraftSyncControllerProvider.notifier).syncPendingDrafts();
  }

  void _listenForRunSessionChanges() {
    ref.listen(runSessionListProvider, (previous, next) {
      if (previous?.hasValue == true && next.hasValue) {
        _syncRecentWatchGhostConfigs();
      }
    });
  }

  void _listenForRunSettingsChanges() {
    ref.listen(runSettingsControllerProvider, (previous, next) {
      final previousWorkout = previous?.value?.intervalWorkout;
      final nextWorkout = next.value?.intervalWorkout;
      if (previousWorkout != null &&
          nextWorkout != null &&
          previousWorkout.toJson().toString() !=
              nextWorkout.toJson().toString()) {
        _syncWatchIntervalConfig();
      }
      final previousVolume = previous?.value?.voiceCueVolume;
      final nextVolume = next.value?.voiceCueVolume;
      final previousVoiceEnabled = previous?.value?.voiceCueEnabled;
      final nextVoiceEnabled = next.value?.voiceCueEnabled;
      final previousKmVoiceEnabled = previous?.value?.kmVoiceCueEnabled;
      final nextKmVoiceEnabled = next.value?.kmVoiceCueEnabled;
      final previousGhostVoiceEnabled = previous?.value?.ghostVoiceCueEnabled;
      final nextGhostVoiceEnabled = next.value?.ghostVoiceCueEnabled;
      final previousAutoPauseEnabled = previous?.value?.autoPauseEnabled;
      final nextAutoPauseEnabled = next.value?.autoPauseEnabled;
      final voiceSettingsChanged =
          previousVolume != nextVolume ||
          previousVoiceEnabled != nextVoiceEnabled ||
          previousKmVoiceEnabled != nextKmVoiceEnabled ||
          previousGhostVoiceEnabled != nextGhostVoiceEnabled ||
          previousAutoPauseEnabled != nextAutoPauseEnabled;
      if (nextVolume != null && voiceSettingsChanged) {
        _syncWatchVoiceSettings(
          playTestCue: previousVolume != null && previousVolume != nextVolume,
        );
      }
    });
  }

  Future<void> _syncWatchIntervalConfig() async {
    if (!mounted) {
      return;
    }
    final settings = ref.read(runSettingsControllerProvider).value;
    if (settings == null) {
      return;
    }
    try {
      await ref
          .read(watchIntervalConfigClientProvider)
          .sendIntervalWorkout(settings.intervalWorkout);
    } catch (_) {
      // Wear interval config sync is best-effort and retried on foreground.
    }
  }

  Future<void> _syncWatchVoiceSettings({bool playTestCue = false}) async {
    if (!mounted) {
      return;
    }
    final settings = ref.read(runSettingsControllerProvider).value;
    if (settings == null) {
      return;
    }
    try {
      await ref
          .read(watchVoiceSettingsClientProvider)
          .sendVoiceSettings(
            voiceCueEnabled: settings.voiceCueEnabled,
            kmVoiceCueEnabled: settings.kmVoiceCueEnabled,
            ghostVoiceCueEnabled: settings.ghostVoiceCueEnabled,
            autoPauseEnabled: settings.autoPauseEnabled,
            volume: settings.voiceCueVolume,
            playTestCue: playTestCue,
          );
    } catch (_) {
      // Wear voice settings sync is best-effort and retried on foreground.
    }
  }

  Future<void> _syncRecentWatchGhostConfigs() async {
    if (!mounted) {
      return;
    }
    try {
      final sessions = await ref.read(runSessionListProvider.future);
      if (!mounted) {
        return;
      }
      final selectedSessionId = ref
          .read(ghostSettingsProvider)
          .selectedSessionId;
      await ref
          .read(watchGhostConfigSyncServiceProvider)
          .syncRecentSessions(sessions, selectedSessionId: selectedSessionId);
    } catch (_) {
      // Wear config sync is best-effort and retried on foreground.
    }
  }
}

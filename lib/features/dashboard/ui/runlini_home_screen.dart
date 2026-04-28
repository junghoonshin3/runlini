import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/dashboard/ui/run_start_countdown_overlay.dart';
import 'package:runlini/features/ghost_racer/state/ghost_racer_providers.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/ui/history/history_tab_screen.dart';
import 'package:runlini/features/run_tracking/ui/running/running_tab_screen.dart';
import 'package:runlini/features/settings/ui/settings_tab_screen.dart';
import 'package:runlini/features/settings/ui/startup_weight_screen.dart';

class RunliniHomeScreen extends ConsumerStatefulWidget {
  const RunliniHomeScreen({super.key});

  @override
  ConsumerState<RunliniHomeScreen> createState() => _RunliniHomeScreenState();
}

class _RunliniHomeScreenState extends ConsumerState<RunliniHomeScreen>
    with WidgetsBindingObserver {
  bool _healthSyncScheduled = false;
  bool _wearDraftSyncScheduled = false;
  bool _wearGhostConfigSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWearDrafts();
      _syncWearGhostConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(appTabProvider);
    final countdownState = ref.watch(runStartCountdownControllerProvider);
    final settingsState = ref.watch(runSettingsControllerProvider);
    final promptEnabled = ref.watch(startupWeightPromptEnabledProvider);

    if (promptEnabled &&
        settingsState.isLoading &&
        settingsState.value == null) {
      return const _StartupLoadingScreen();
    }

    if (promptEnabled && settingsState.value?.bodyWeightKg == null) {
      return const StartupWeightScreen();
    }

    _scheduleHealthSync();
    _scheduleWearDraftSync();
    _scheduleWearGhostConfigSync();

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: currentTab.index,
            children: const [
              HistoryTabScreen(),
              RunningTabScreen(),
              SettingsTabScreen(),
            ],
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.panel,
              border: Border(top: BorderSide(color: AppColors.chalk, width: 3)),
            ),
            child: BottomNavigationBar(
              currentIndex: currentTab.index,
              onTap: (int index) {
                if (countdownState.isActive) {
                  return;
                }
                ref.read(appTabProvider.notifier).setTab(AppTab.values[index]);
              },
              backgroundColor: AppColors.panel,
              selectedItemColor: AppColors.voltGreen,
              unselectedItemColor: AppColors.muted,
              selectedFontSize: 14,
              unselectedFontSize: 14,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_rounded),
                  label: '기록',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.directions_run_rounded),
                  label: '러닝',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: '설정',
                ),
              ],
            ),
          ),
        ),
        if (countdownState.isActive)
          RunStartCountdownOverlay(
            remainingSeconds: countdownState.remainingSeconds!,
          ),
      ],
    );
  }

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
      _syncWearGhostConfig();
    });
  }

  void _syncWearDrafts() {
    if (!mounted) {
      return;
    }
    ref.read(wearDraftSyncControllerProvider.notifier).syncPendingDrafts();
  }

  Future<void> _syncWearGhostConfig() async {
    if (!mounted) {
      return;
    }
    try {
      final session = await ref.read(selectedGhostSessionProvider.future);
      if (!mounted) {
        return;
      }
      await ref.read(watchGhostConfigSyncServiceProvider).syncSession(session);
    } catch (_) {
      // Wear config sync is best-effort and retried on foreground.
    }
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(color: AppColors.voltGreen),
        ),
      ),
    );
  }
}

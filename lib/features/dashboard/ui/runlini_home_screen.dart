import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/core/performance/startup_trace.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/dashboard/ui/run_start_countdown_overlay.dart';
import 'package:runlini/features/health_sync/state/health_sync_providers.dart';
import 'package:runlini/features/record_race/state/record_race_providers.dart';
import 'package:runlini/features/run_tracking/state/run_playback_providers.dart';
import 'package:runlini/features/run_tracking/state/run_session_providers.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/state/run_watch_providers.dart';
import 'package:runlini/features/run_tracking/ui/history/history_tab_screen.dart';
import 'package:runlini/features/run_tracking/ui/running/running_tab_screen.dart';
import 'package:runlini/features/settings/ui/settings_tab_screen.dart';

part 'runlini_home_screen_sync.dart';

class RunliniHomeScreen extends ConsumerStatefulWidget {
  const RunliniHomeScreen({super.key});

  @override
  ConsumerState<RunliniHomeScreen> createState() => _RunliniHomeScreenState();
}

class _RunliniHomeScreenState extends ConsumerState<RunliniHomeScreen>
    with WidgetsBindingObserver {
  bool _startupSyncScheduled = false;
  Timer? _startupSyncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _startupSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncWearDrafts();
      _syncRecentWatchRecordRaceConfigs();
      _syncWatchIntervalConfig();
      _syncWatchVoiceSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(appTabProvider);
    final countdownState = ref.watch(runStartCountdownControllerProvider);
    final hasRunFocusState = ref.watch(
      runPlaybackControllerProvider.select(
        (state) =>
            state.hasActiveSession ||
            state.isReviewing ||
            state.recordRaceCompletionPromptPending,
      ),
    );
    final showBottomNavigation = !countdownState.isActive && !hasRunFocusState;

    _listenForRunSessionChanges();
    _listenForRunSettingsChanges();
    _scheduleStartupSync();

    return Stack(
      children: [
        Scaffold(
          body: LazyTabStack(
            index: currentTab.index,
            children: const <Widget>[
              HistoryTabScreen(),
              RunningTabScreen(),
              SettingsTabScreen(),
            ],
          ),
          bottomNavigationBar: showBottomNavigation
              ? _RunliniBottomNavigationBar(
                  currentTab: currentTab,
                  onSelected: (AppTab tab) {
                    ref.read(appTabProvider.notifier).setTab(tab);
                  },
                )
              : null,
        ),
        if (countdownState.isActive)
          RunStartCountdownOverlay(
            remainingSeconds: countdownState.remainingSeconds!,
          ),
      ],
    );
  }
}

class _RunliniBottomNavigationBar extends StatelessWidget {
  const _RunliniBottomNavigationBar({
    required this.currentTab,
    required this.onSelected,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border(
          top: BorderSide(color: AppColors.chalk.withValues(alpha: 0.18)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          key: const Key('runlini-bottom-navigation'),
          currentIndex: currentTab.index,
          onTap: (int index) => onSelected(AppTab.values[index]),
          backgroundColor: AppColors.panel,
          elevation: 0,
          selectedItemColor: AppColors.voltGreen,
          unselectedItemColor: AppColors.muted,
          selectedFontSize: 13,
          unselectedFontSize: 13,
          selectedIconTheme: const IconThemeData(size: 28),
          unselectedIconTheme: const IconThemeData(size: 24),
          selectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
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
    );
  }
}

class LazyTabStack extends StatefulWidget {
  const LazyTabStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<LazyTabStack> createState() => _LazyTabStackState();
}

class _LazyTabStackState extends State<LazyTabStack> {
  final Set<int> _mountedIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _mountedIndexes.add(widget.index);
  }

  @override
  void didUpdateWidget(covariant LazyTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _mountedIndexes.add(widget.index);
    _mountedIndexes.removeWhere((index) => index >= widget.children.length);
  }

  @override
  Widget build(BuildContext context) {
    final mountedIndexes = _mountedIndexes.toList()..sort();
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final index in mountedIndexes)
          Offstage(
            offstage: index != widget.index,
            child: TickerMode(
              enabled: index == widget.index,
              child: widget.children[index],
            ),
          ),
      ],
    );
  }
}

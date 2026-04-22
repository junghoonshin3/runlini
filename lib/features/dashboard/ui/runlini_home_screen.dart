import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/dashboard/state/app_shell_providers.dart';
import 'package:runlini/features/dashboard/types/app_tab.dart';
import 'package:runlini/features/run_tracking/state/run_start_countdown_providers.dart';
import 'package:runlini/features/run_tracking/ui/history_tab_screen.dart';
import 'package:runlini/features/run_tracking/ui/running_tab_screen.dart';

class RunliniHomeScreen extends ConsumerWidget {
  const RunliniHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(appTabProvider);
    final countdownState = ref.watch(runStartCountdownControllerProvider);

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: currentTab.index,
            children: const [HistoryTabScreen(), RunningTabScreen()],
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
              ],
            ),
          ),
        ),
        if (countdownState.isActive)
          _RunStartCountdownOverlay(
            remainingSeconds: countdownState.remainingSeconds!,
          ),
      ],
    );
  }
}

class _RunStartCountdownOverlay extends StatelessWidget {
  const _RunStartCountdownOverlay({required this.remainingSeconds});

  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ModalBarrier(
            key: Key('run-start-countdown-overlay'),
            color: Color(0xCC000000),
            dismissible: false,
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              key: const Key('run-start-countdown-number'),
              child: _AnimatedCountdownNumber(
                key: ValueKey<int>(remainingSeconds),
                remainingSeconds: remainingSeconds,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedCountdownNumber extends StatefulWidget {
  const _AnimatedCountdownNumber({super.key, required this.remainingSeconds});

  final int remainingSeconds;

  @override
  State<_AnimatedCountdownNumber> createState() =>
      _AnimatedCountdownNumberState();
}

class _AnimatedCountdownNumberState extends State<_AnimatedCountdownNumber>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(seconds: 1);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _animationDuration,
  )..forward();

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem<double>(
      tween: Tween<double>(
        begin: 0,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 18,
    ),
    TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 56),
    TweenSequenceItem<double>(
      tween: Tween<double>(
        begin: 1,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 26,
    ),
  ]).animate(_controller);

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem<double>(
      tween: Tween<double>(
        begin: 0.82,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 18,
    ),
    TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 56),
    TweenSequenceItem<double>(
      tween: Tween<double>(
        begin: 1,
        end: 0.94,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 26,
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      color: AppColors.chalk,
      fontSize: 168,
      fontWeight: FontWeight.w900,
    );

    return AnimatedBuilder(
      animation: _controller,
      child: Text(
        '${widget.remainingSeconds}',
        key: const Key('run-start-countdown-label'),
        style: textStyle,
      ),
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
    );
  }
}

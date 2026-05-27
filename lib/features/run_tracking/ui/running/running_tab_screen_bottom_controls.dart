part of 'running_tab_screen.dart';

// 러닝 탭 하단 컨트롤 묶음의 배치와 START 전환 모션을 관리한다.
const _runBottomControlsHiddenKey = ValueKey<String>(
  'run-bottom-controls-hidden',
);
const _runBottomControlsExitOffsetY = 20.0;

extension _RunningTabScreenBottomControls on _RunningTabScreenState {
  Widget _buildBottomControlsLayer({
    required BuildContext context,
    required RunPlaybackState playbackState,
    required RunIntervalWorkout intervalWorkout,
    required bool showBottomControls,
    required double activeRunBottomInset,
    required double activeRunCenterBottomInset,
  }) {
    return Positioned.fill(
      key: const ValueKey<String>('run-bottom-controls-layer'),
      child: _RunBottomControlsExit(
        show: showBottomControls,
        child: _buildBottomControls(
          context: context,
          playbackState: playbackState,
          intervalWorkout: intervalWorkout,
          activeRunBottomInset: activeRunBottomInset,
          activeRunCenterBottomInset: activeRunCenterBottomInset,
        ),
      ),
    );
  }

  Widget _buildBottomControls({
    required BuildContext context,
    required RunPlaybackState playbackState,
    required RunIntervalWorkout intervalWorkout,
    required double activeRunBottomInset,
    required double activeRunCenterBottomInset,
  }) {
    return Stack(
      key: ValueKey<String>(
        playbackState.hasActiveSession
            ? 'run-bottom-controls-active'
            : 'run-bottom-controls-idle',
      ),
      children: [
        Positioned(
          left: 20,
          bottom: playbackState.hasActiveSession ? activeRunBottomInset : 28,
          child: AnimatedSwitcher(
            duration: RunliniMotion.enabledDuration(
              context,
              RunliniMotion.shortTransition,
            ),
            switchInCurve: RunliniMotion.enterCurve,
            switchOutCurve: RunliniMotion.exitCurve,
            transitionBuilder: _runControlTransition,
            child: playbackState.hasActiveSession
                ? RunPauseResumeButton(
                    key: const ValueKey<String>('pause-resume-control'),
                    isPaused: playbackState.status == RunScreenStatus.paused,
                    onPressed: () async {
                      await _handlePauseResumePressed(
                        playbackState: playbackState,
                      );
                    },
                  )
                : RunIntervalButton(
                    key: const ValueKey<String>('interval-control'),
                    workout: intervalWorkout,
                    onPressed: () => _handleIntervalButtonPressed(context),
                  ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: playbackState.hasActiveSession ? activeRunBottomInset : 28,
          child: RunCurrentLocationButton(
            onPressed: () async {
              await _handleCurrentLocationPressed(context);
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: playbackState.hasActiveSession
              ? activeRunCenterBottomInset
              : 24,
          child: Center(
            child: RunStartStopButton(
              showsStopAction: playbackState.hasActiveSession,
              onPressed: () async {
                await _handleStartStopPressed(
                  context: context,
                  playbackState: playbackState,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RunBottomControlsExit extends StatefulWidget {
  const _RunBottomControlsExit({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  State<_RunBottomControlsExit> createState() => _RunBottomControlsExitState();
}

class _RunBottomControlsExitState extends State<_RunBottomControlsExit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late bool _renderChild;

  @override
  void initState() {
    super.initState();
    _renderChild = widget.show;
    _controller = AnimationController(vsync: this, value: widget.show ? 1 : 0);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: RunliniMotion.enterCurve,
      reverseCurve: RunliniMotion.exitCurve,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDuration();
  }

  @override
  void didUpdateWidget(covariant _RunBottomControlsExit oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDuration();
    if (widget.show) {
      if (!_renderChild) {
        setState(() {
          _renderChild = true;
        });
      }
      _controller.forward();
      return;
    }

    if (RunliniMotion.reduceMotion(context)) {
      _controller.value = 0;
      if (_renderChild) {
        setState(() {
          _renderChild = false;
        });
      }
      return;
    }

    _renderChild = true;
    _controller.reverse().whenComplete(() {
      if (!mounted ||
          widget.show ||
          _controller.status != AnimationStatus.dismissed) {
        return;
      }
      setState(() {
        _renderChild = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncDuration() {
    final duration = RunliniMotion.enabledDuration(
      context,
      RunliniMotion.shortTransition,
    );
    _controller.duration = duration;
    _controller.reverseDuration = duration;
  }

  @override
  Widget build(BuildContext context) {
    if (!_renderChild) {
      return const SizedBox.shrink(key: _runBottomControlsHiddenKey);
    }
    return IgnorePointer(
      ignoring: !widget.show,
      child: ExcludeSemantics(
        excluding: !widget.show,
        child: FadeTransition(
          opacity: _animation,
          child: AnimatedBuilder(
            animation: _animation,
            child: widget.child,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  _runBottomControlsExitOffsetY * (1 - _animation.value),
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

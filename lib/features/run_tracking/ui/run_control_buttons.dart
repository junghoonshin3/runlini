import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunSettingsButton extends StatelessWidget {
  const RunSettingsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 68,
      child: IconButton(
        key: const Key('settings-button'),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.black.withValues(alpha: 0.9),
          foregroundColor: AppColors.chalk,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.chalk, width: 3),
          ),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.tune_rounded, size: 28),
        tooltip: 'Settings',
      ),
    );
  }
}

class RunPauseResumeButton extends StatelessWidget {
  const RunPauseResumeButton({
    super.key,
    required this.isPaused,
    required this.onPressed,
  });

  final bool isPaused;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 68,
      child: IconButton(
        key: Key(isPaused ? 'resume-run-button' : 'pause-run-button'),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.black.withValues(alpha: 0.9),
          foregroundColor: isPaused ? AppColors.voltGreen : AppColors.chalk,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.chalk, width: 3),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(
          isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          size: 32,
        ),
        tooltip: isPaused ? 'Resume run' : 'Pause run',
      ),
    );
  }
}

class RunStartStopButton extends StatelessWidget {
  const RunStartStopButton({
    super.key,
    required this.showsStopAction,
    required this.onPressed,
  });

  final bool showsStopAction;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 120,
      child: FilledButton(
        key: const Key('start-stop-button'),
        style: FilledButton.styleFrom(
          backgroundColor: showsStopAction
              ? AppColors.electricRed
              : AppColors.voltGreen,
          foregroundColor: showsStopAction ? AppColors.chalk : AppColors.black,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.black, width: 4),
          ),
          padding: EdgeInsets.zero,
          textStyle: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(showsStopAction ? 'STOP' : 'START'),
          ),
        ),
      ),
    );
  }
}

class RunCurrentLocationButton extends StatelessWidget {
  const RunCurrentLocationButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 68,
      child: IconButton(
        key: const Key('current-location-button'),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.black.withValues(alpha: 0.9),
          foregroundColor: AppColors.voltGreen,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.chalk, width: 3),
          ),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.my_location_rounded, size: 28),
        tooltip: 'Current location',
      ),
    );
  }
}

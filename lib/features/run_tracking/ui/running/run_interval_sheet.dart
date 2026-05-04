import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/state/run_settings_providers.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';
import 'package:runlini/features/run_tracking/types/run_settings.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet_buttons.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet_components.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_sheet_simple_components.dart';
import 'package:runlini/features/run_tracking/ui/running/run_interval_target_card.dart';

Future<void> showRunIntervalSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 140),
      reverseDuration: Duration(milliseconds: 80),
    ),
    builder: (_) => const RunIntervalSheet(),
  );
}

class RunIntervalSheet extends ConsumerWidget {
  const RunIntervalSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(runSettingsControllerProvider).value ??
        const RunSettingsState();
    final workout = _simpleIntervalWorkoutForUi(settings.intervalWorkout);
    final controller = ref.read(runSettingsControllerProvider.notifier);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      key: const Key('run-interval-draggable-sheet'),
      expand: false,
      initialChildSize: 1.0,
      minChildSize: 0.0,
      maxChildSize: 1.0,
      snap: true,
      snapAnimationDuration: const Duration(milliseconds: 80),
      shouldCloseOnMinExtent: true,
      builder: (context, scrollController) {
        return SafeArea(
          top: true,
          child: Container(
            key: const Key('run-interval-sheet'),
            color: AppColors.black,
            child: CustomScrollView(
              key: const Key('run-interval-sheet-scroll'),
              controller: scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: RunIntervalSheetHeader(
                      workout: workout,
                      onEnabledChanged: (enabled) {
                        controller.setIntervalWorkout(
                          workout.copyWith(enabled: enabled),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      RunIntervalTargetCard(
                        title: '질주',
                        target: workout.work,
                        accent: AppColors.voltGreen,
                        timeFallback: _oneMinute,
                        distanceFallback: _fourHundredMeters,
                        onChanged: (target) {
                          controller.setIntervalWorkout(
                            workout.copyWith(work: target),
                          );
                        },
                      ),
                      RunIntervalTargetCard(
                        title: '휴식',
                        target: workout.recovery,
                        timeFallback: _oneMinute,
                        distanceFallback: _twoHundredMeters,
                        onChanged: (target) {
                          controller.setIntervalWorkout(
                            workout.copyWith(recovery: target),
                          );
                        },
                      ),
                      RunIntervalRepeatCard(
                        repeatCount: workout.repeatCount,
                        onChanged: (repeatCount) {
                          controller.setIntervalWorkout(
                            workout.copyWith(repeatCount: repeatCount),
                          );
                        },
                      ),
                      RunIntervalWarmCooldownCard(
                        warmupEnabled:
                            workout.warmup.type != RunIntervalTargetType.skip,
                        cooldownEnabled:
                            workout.cooldown.type != RunIntervalTargetType.skip,
                        onWarmupChanged: (enabled) {
                          controller.setIntervalWorkout(
                            workout.copyWith(
                              warmup: enabled
                                  ? const RunIntervalTarget.time(5 * 60 * 1000)
                                  : const RunIntervalTarget.skip(),
                            ),
                          );
                        },
                        onCooldownChanged: (enabled) {
                          controller.setIntervalWorkout(
                            workout.copyWith(
                              cooldown: enabled
                                  ? const RunIntervalTarget.time(5 * 60 * 1000)
                                  : const RunIntervalTarget.skip(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      RunIntervalDoneButton(
                        onPressed: () => Navigator.pop(context),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RunIntervalButton extends StatelessWidget {
  const RunIntervalButton({
    super.key,
    required this.workout,
    required this.onPressed,
  });

  final RunIntervalWorkout workout;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = workout.enabled;
    final color = active ? AppColors.voltGreen : AppColors.chalk;
    return SizedBox.square(
      dimension: 68,
      child: OutlinedButton(
        key: const Key('run-interval-button'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: AppColors.black.withValues(alpha: 0.9),
          side: BorderSide(color: color, width: 3),
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 23),
                const SizedBox(height: 2),
                Text(
                  '인터벌',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (active)
              Positioned(
                top: 9,
                right: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.voltGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'ON',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _oneMinute = RunIntervalTarget.time(60 * 1000);
const _fourHundredMeters = RunIntervalTarget.distance(400);
const _twoHundredMeters = RunIntervalTarget.distance(200);

RunIntervalWorkout _simpleIntervalWorkoutForUi(RunIntervalWorkout workout) {
  return workout.copyWith(
    warmup: _simpleWarmCooldown(workout.warmup),
    work: _simpleTarget(workout.work, _oneMinute),
    recovery: _simpleTarget(workout.recovery, _oneMinute),
    repeatCount: workout.repeatCount.clamp(1, 30),
    cooldown: _simpleWarmCooldown(workout.cooldown),
  );
}

RunIntervalTarget _simpleTarget(
  RunIntervalTarget target,
  RunIntervalTarget fallback,
) {
  if (target.type == RunIntervalTargetType.time ||
      target.type == RunIntervalTargetType.distance) {
    return target;
  }
  return fallback;
}

RunIntervalTarget _simpleWarmCooldown(RunIntervalTarget target) {
  if (target.type == RunIntervalTargetType.skip) {
    return target;
  }
  return const RunIntervalTarget.time(5 * 60 * 1000);
}

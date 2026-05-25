// Runlini 앱 UI의 공통 모션 시간과 곡선을 정의한다
import 'package:flutter/material.dart';

abstract final class RunliniMotion {
  static const Duration fastTransition = Duration(milliseconds: 80);
  static const Duration shortTransition = Duration(milliseconds: 140);
  static const Duration standardTransition = Duration(milliseconds: 220);
  static const Duration countdownStep = Duration(milliseconds: 1000);
  static const Duration skeletonShimmer = Duration(milliseconds: 900);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration enabledDuration(BuildContext context, Duration duration) {
    return reduceMotion(context) ? Duration.zero : duration;
  }
}

class RunliniFadeUp extends StatelessWidget {
  const RunliniFadeUp({
    super.key,
    required this.child,
    this.duration = RunliniMotion.shortTransition,
    this.offset = 8,
  });

  final Widget child;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (RunliniMotion.reduceMotion(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: RunliniMotion.enterCurve,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class RunliniOverlayEntrance extends StatelessWidget {
  const RunliniOverlayEntrance({
    super.key,
    required this.child,
    this.duration = RunliniMotion.shortTransition,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (RunliniMotion.reduceMotion(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.92, end: 1),
      duration: duration,
      curve: RunliniMotion.enterCurve,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
}

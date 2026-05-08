// Runlini 공통 스켈레톤 로딩 컴포넌트
import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunliniSkeletonBox extends StatefulWidget {
  const RunliniSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.baseColor,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color? baseColor;

  @override
  State<RunliniSkeletonBox> createState() => _RunliniSkeletonBoxState();
}

class _RunliniSkeletonBoxState extends State<RunliniSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) &&
        _controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.graphite;
    final radius = BorderRadius.circular(widget.borderRadius);
    if (MediaQuery.disableAnimationsOf(context)) {
      return _SkeletonSurface(
        width: widget.width,
        height: widget.height,
        radius: radius,
        color: base,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final sweep = -1.4 + (_controller.value * 2.8);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(sweep - 0.8, -0.35),
              end: Alignment(sweep + 0.8, 0.35),
              colors: [
                base.withValues(alpha: 0.72),
                AppColors.chalk.withValues(alpha: 0.12),
                base.withValues(alpha: 0.72),
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}

class RunliniSkeletonText extends StatelessWidget {
  const RunliniSkeletonText({
    super.key,
    this.width = 120,
    this.height = 14,
    this.borderRadius = 4,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return RunliniSkeletonBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      baseColor: AppColors.muted.withValues(alpha: 0.22),
    );
  }
}

class RunliniSkeletonPanel extends StatelessWidget {
  const RunliniSkeletonPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(
          color: borderColor ?? AppColors.chalk.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class RunliniSkeletonTile extends StatelessWidget {
  const RunliniSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return RunliniSkeletonPanel(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.chalk.withValues(alpha: 0.22),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RunliniSkeletonText(width: 168, height: 20),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SkeletonMetric()),
              SizedBox(width: 14),
              Expanded(child: _SkeletonMetric()),
              SizedBox(width: 14),
              Expanded(child: _SkeletonMetric()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonSurface extends StatelessWidget {
  const _SkeletonSurface({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  final double? width;
  final double height;
  final BorderRadius radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: radius),
    );
  }
}

class _SkeletonMetric extends StatelessWidget {
  const _SkeletonMetric();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RunliniSkeletonText(width: 48, height: 12),
        SizedBox(height: 8),
        RunliniSkeletonText(width: 64, height: 18),
      ],
    );
  }
}

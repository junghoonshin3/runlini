import 'package:flutter/material.dart';

class RouteSpeedPopoverPlacement {
  const RouteSpeedPopoverPlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.maxHeight,
  });

  final double left;
  final double top;
  final double width;
  final double maxHeight;
}

RouteSpeedPopoverPlacement routeSpeedPopoverPlacement({
  required Rect anchor,
  required Size viewport,
  required EdgeInsets safePadding,
  double margin = 12,
  double gap = 6,
  double preferredWidth = 244,
  double estimatedHeight = 164,
}) {
  final safeLeft = margin + safePadding.left;
  final safeRight = viewport.width - margin - safePadding.right;
  final safeTop = margin + safePadding.top;
  final rawSafeBottom = viewport.height - margin - safePadding.bottom;
  final safeBottom = rawSafeBottom < safeTop + 64
      ? safeTop + 64
      : rawSafeBottom;
  final availableWidth = safeRight - safeLeft < 0 ? 0.0 : safeRight - safeLeft;
  final width = preferredWidth.clamp(0, availableWidth).toDouble();
  final preferredLeft = anchor.right - width;
  final left = preferredLeft.clamp(safeLeft, safeRight - width).toDouble();

  final belowTop = anchor.bottom + gap;
  final belowSpace = safeBottom - belowTop;
  final aboveTop = anchor.top - gap - estimatedHeight;
  final showAbove = belowSpace < estimatedHeight && aboveTop >= safeTop;
  final top = showAbove
      ? aboveTop
      : belowTop.clamp(safeTop, safeBottom - 64).toDouble();
  final rawMaxHeight = showAbove ? anchor.top - gap - top : safeBottom - top;
  final maxHeight = rawMaxHeight.clamp(64, safeBottom - safeTop).toDouble();
  return RouteSpeedPopoverPlacement(
    left: left,
    top: top,
    width: width,
    maxHeight: maxHeight,
  );
}

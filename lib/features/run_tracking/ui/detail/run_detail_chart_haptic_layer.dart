// 기록 상세 차트의 드래그 선택 햅틱 레이어를 제공하는 위젯
import 'package:flutter/material.dart';

class RunDetailChartHapticLayer extends StatefulWidget {
  const RunDetailChartHapticLayer({
    super.key,
    required this.bucketCount,
    required this.onSelected,
    required this.onReset,
    required this.child,
  });

  final int bucketCount;
  final ValueChanged<int> onSelected;
  final VoidCallback onReset;
  final Widget child;

  @override
  State<RunDetailChartHapticLayer> createState() =>
      _RunDetailChartHapticLayerState();
}

class _RunDetailChartHapticLayerState extends State<RunDetailChartHapticLayer> {
  static const _dragThresholdPx = 8.0;

  Offset? _startPosition;
  bool _isDragging = false;
  int? _lastBucketIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) =>
              _handleDown(event.localPosition, constraints.maxWidth),
          onPointerMove: (event) =>
              _handleMove(event.localPosition, constraints.maxWidth),
          onPointerUp: (_) => _reset(),
          onPointerCancel: (_) => _reset(),
          child: widget.child,
        );
      },
    );
  }

  void _handleDown(Offset position, double width) {
    _startPosition = position;
    _isDragging = false;
    _lastBucketIndex = _bucketIndexFor(position.dx, width);
  }

  void _handleMove(Offset position, double width) {
    final startPosition = _startPosition;
    if (startPosition == null) {
      return;
    }
    if (!_isDragging) {
      final hasDragged =
          (position - startPosition).distance >= _dragThresholdPx;
      if (!hasDragged) {
        return;
      }
      _isDragging = true;
    }

    final nextIndex = _bucketIndexFor(position.dx, width);
    if (nextIndex == null || nextIndex == _lastBucketIndex) {
      return;
    }
    _lastBucketIndex = nextIndex;
    widget.onSelected(nextIndex);
  }

  void _reset() {
    _startPosition = null;
    _isDragging = false;
    _lastBucketIndex = null;
    widget.onReset();
  }

  int? _bucketIndexFor(double dx, double width) {
    if (widget.bucketCount <= 0 || !width.isFinite || width <= 0) {
      return null;
    }
    final rawIndex = ((dx / width) * widget.bucketCount).floor();
    return rawIndex.clamp(0, widget.bucketCount - 1).toInt();
  }
}

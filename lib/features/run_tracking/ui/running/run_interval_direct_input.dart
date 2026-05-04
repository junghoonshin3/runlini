import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_interval_workout.dart';

class RunIntervalDirectTargetInput extends StatefulWidget {
  const RunIntervalDirectTargetInput({
    super.key,
    required this.title,
    required this.target,
    required this.isDistance,
    required this.onChanged,
  });

  final String title;
  final RunIntervalTarget target;
  final bool isDistance;
  final ValueChanged<RunIntervalTarget> onChanged;

  @override
  State<RunIntervalDirectTargetInput> createState() =>
      _RunIntervalDirectTargetInputState();
}

class _RunIntervalDirectTargetInputState
    extends State<RunIntervalDirectTargetInput> {
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  late final TextEditingController _distanceController;
  late String _targetSignature;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController();
    _secondsController = TextEditingController();
    _distanceController = TextEditingController();
    _targetSignature = '';
    _syncControllers();
  }

  @override
  void didUpdateWidget(RunIntervalDirectTargetInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = _signature(widget.target, widget.isDistance);
    if (signature != _targetSignature) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('run-interval-${widget.title}-direct-input'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.graphite, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('직접 입력', style: _labelStyle(context)),
          const SizedBox(height: 8),
          widget.isDistance ? _distanceInput() : _timeInput(),
        ],
      ),
    );
  }

  Widget _timeInput() {
    return Row(
      children: [
        Expanded(
          child: _NumberField(
            fieldKey: Key('run-interval-${widget.title}-direct-minutes'),
            controller: _minutesController,
            unit: '분',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NumberField(
            fieldKey: Key('run-interval-${widget.title}-direct-seconds'),
            controller: _secondsController,
            unit: '초',
          ),
        ),
        const SizedBox(width: 8),
        _ApplyButton(
          key: Key('run-interval-${widget.title}-direct-apply'),
          onPressed: _applyTime,
        ),
      ],
    );
  }

  Widget _distanceInput() {
    return Row(
      children: [
        Expanded(
          child: _NumberField(
            fieldKey: Key('run-interval-${widget.title}-direct-distance'),
            controller: _distanceController,
            unit: 'm',
          ),
        ),
        const SizedBox(width: 8),
        _ApplyButton(
          key: Key('run-interval-${widget.title}-direct-apply'),
          onPressed: _applyDistance,
        ),
      ],
    );
  }

  void _applyTime() {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final totalSeconds = (minutes * 60 + seconds).clamp(10, 1800).toInt();
    widget.onChanged(RunIntervalTarget.time(totalSeconds * 1000));
  }

  void _applyDistance() {
    final meters = int.tryParse(_distanceController.text);
    if (meters == null) {
      return;
    }
    widget.onChanged(
      RunIntervalTarget.distance(meters.clamp(50, 10000).toDouble()),
    );
  }

  void _syncControllers() {
    _targetSignature = _signature(widget.target, widget.isDistance);
    if (widget.isDistance) {
      _distanceController.text = ((widget.target.distanceM ?? 400).round())
          .toString();
      return;
    }
    final totalSeconds = ((widget.target.durationMs ?? 60000) / 1000).round();
    _minutesController.text = (totalSeconds ~/ 60).toString();
    _secondsController.text = (totalSeconds % 60).toString();
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.unit,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        color: AppColors.chalk,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.panel,
        suffixText: unit,
        suffixStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w900,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        enabledBorder: _fieldBorder(AppColors.graphite),
        focusedBorder: _fieldBorder(AppColors.voltGreen),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 42,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.black,
          backgroundColor: AppColors.voltGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: EdgeInsets.zero,
        ),
        child: const Text(
          '적용',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

OutlineInputBorder _fieldBorder(Color color) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: color, width: 2),
  );
}

TextStyle? _labelStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge?.copyWith(
    color: AppColors.muted,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );
}

String _signature(RunIntervalTarget target, bool isDistance) {
  return '${target.type.name}:${target.durationMs}:${target.distanceM}:$isDistance';
}

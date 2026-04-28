import 'package:flutter/material.dart';

class RunFinishReviewActions extends StatelessWidget {
  const RunFinishReviewActions({
    super.key,
    required this.onSave,
    required this.onDiscard,
  });

  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              key: const Key('save-run-button'),
              onPressed: onSave,
              child: const Text('저장하기'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              key: const Key('discard-run-button'),
              onPressed: onDiscard,
              child: const Text('기록 버리기'),
            ),
          ),
        ],
      ),
    );
  }
}

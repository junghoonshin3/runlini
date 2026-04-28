import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/types/run_shoe.dart';

class RunShoeAssignmentSheet extends StatelessWidget {
  const RunShoeAssignmentSheet({
    super.key,
    required this.shoes,
    required this.currentShoeId,
  });

  final List<RunShoe> shoes;
  final String? currentShoeId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('러닝화 연결', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('이 기록의 거리를 선택한 러닝화 누적 km에 더해요.', style: _mutedStyle),
            const SizedBox(height: 14),
            if (shoes.isEmpty)
              const Text('등록된 러닝화가 없어요.', style: _mutedStyle)
            else
              ...shoes.map((shoe) => _ShoeOption(shoe, currentShoeId)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('detail-add-shoe-button'),
                onPressed: () => Navigator.of(
                  context,
                ).pop(const RunShoeAssignmentResult.addNew()),
                child: const Text('새 러닝화 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoeOption extends StatelessWidget {
  const _ShoeOption(this.shoe, this.currentShoeId);

  final RunShoe shoe;
  final String? currentShoeId;

  @override
  Widget build(BuildContext context) {
    final selected = shoe.id == currentShoeId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: Key('detail-select-shoe-${shoe.id}'),
          onPressed: () =>
              Navigator.of(context).pop(RunShoeAssignmentResult.select(shoe)),
          child: Row(
            children: [
              Expanded(child: Text('${shoe.brand} ${shoe.name}')),
              if (selected)
                const Text(
                  '연결됨',
                  style: TextStyle(
                    color: AppColors.voltGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RunShoeAssignmentResult {
  const RunShoeAssignmentResult.addNew() : shoe = null;
  const RunShoeAssignmentResult.select(this.shoe);

  final RunShoe? shoe;

  bool get isAddNew => shoe == null;
}

const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
);

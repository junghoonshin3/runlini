import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_image_thumbnail.dart';

class RunDetailShoeSection extends StatelessWidget {
  const RunDetailShoeSection({
    super.key,
    required this.shoeName,
    this.shoeImagePath,
    this.onManageShoe,
  });

  final String? shoeName;
  final String? shoeImagePath;
  final VoidCallback? onManageShoe;

  @override
  Widget build(BuildContext context) {
    final hasShoe = shoeName != null;
    return Container(
      key: const Key('detail-shoe-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shoeImagePath != null) ...[
                RunShoeImageThumbnail(
                  key: const Key('detail-shoe-image-thumbnail'),
                  imagePath: shoeImagePath!,
                  size: 64,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('러닝화', style: _titleStyle),
                    const SizedBox(height: 8),
                    Text(
                      hasShoe ? shoeName! : '이 기록에 러닝화를 연결하면 신발 누적 거리에 반영돼요.',
                      style: hasShoe ? _valueStyle : _mutedStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (onManageShoe != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 178,
              child: OutlinedButton(
                key: const Key('detail-assign-shoe-button'),
                onPressed: onManageShoe,
                child: Text(hasShoe ? '러닝화 변경' : '러닝화 연결'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w900,
);

const _valueStyle = TextStyle(
  color: AppColors.chalk,
  fontSize: 18,
  fontWeight: FontWeight.w900,
);

const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w800,
);

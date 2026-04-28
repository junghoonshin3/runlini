import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';
import 'package:runlini/features/run_tracking/ui/common/run_shoe_image_thumbnail.dart';

class RunShoeImagePickerPanel extends StatelessWidget {
  const RunShoeImagePickerPanel({
    super.key,
    required this.imagePath,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final String? imagePath;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (path == null)
            const _EmptyImageBox()
          else
            RunShoeImageThumbnail(
              key: const Key('shoe-image-preview'),
              imagePath: path,
              size: 74,
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path == null ? '러닝화 이미지' : '러닝화 이미지 선택됨',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  path == null ? '앨범에서 이미지를 추가해요.' : '목록과 상세 화면에 표시돼요.',
                  style: _mutedStyle,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 178,
                      child: OutlinedButton(
                        key: const Key('shoe-image-picker-button'),
                        onPressed: onPickImage,
                        child: Text(path == null ? '러닝화 이미지 추가' : '이미지 변경'),
                      ),
                    ),
                    if (path != null)
                      SizedBox(
                        width: 126,
                        child: TextButton(
                          key: const Key('shoe-image-remove-button'),
                          onPressed: onRemoveImage,
                          child: const Text('이미지 제거'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyImageBox extends StatelessWidget {
  const _EmptyImageBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.chalk.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.muted),
    );
  }
}

const _mutedStyle = TextStyle(
  color: AppColors.muted,
  fontWeight: FontWeight.w700,
);

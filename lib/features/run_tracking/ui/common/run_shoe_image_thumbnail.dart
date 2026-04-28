import 'dart:io';

import 'package:flutter/material.dart';
import 'package:runlini/app/theme/app_colors.dart';

class RunShoeImageThumbnail extends StatelessWidget {
  const RunShoeImageThumbnail({
    super.key,
    required this.imagePath,
    this.size = 64,
  });

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            color: AppColors.panel,
            child: const Icon(Icons.image_not_supported_outlined),
          );
        },
      ),
    );
  }
}

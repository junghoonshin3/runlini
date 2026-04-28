import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalImageStore {
  Future<String> saveShoeImage(XFile source, {String? replacingPath}) async {
    final directory = await _shoeImageDirectory();
    final targetPath = p.join(
      directory.path,
      'shoe_${DateTime.now().toUtc().microsecondsSinceEpoch}${_extension(source)}',
    );
    await source.saveTo(targetPath);
    if (replacingPath != null && replacingPath != targetPath) {
      await deleteImage(replacingPath);
    }
    return targetPath;
  }

  Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException {
      // Best effort cleanup only. A stale image path should not block saving.
    }
  }

  Future<Directory> _shoeImageDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'shoe_images'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  String _extension(XFile source) {
    final extension = p.extension(source.path).toLowerCase();
    if (extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.png' ||
        extension == '.webp') {
      return extension;
    }
    return '.jpg';
  }
}

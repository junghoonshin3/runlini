import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runlini/core/media/image_picker_client.dart';
import 'package:runlini/core/media/local_image_store.dart';

final imagePickerClientProvider = Provider<ImagePickerClient>((Ref ref) {
  return DeviceImagePickerClient();
});

final localImageStoreProvider = Provider<LocalImageStore>((Ref ref) {
  return LocalImageStore();
});

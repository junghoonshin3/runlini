import 'package:image_picker/image_picker.dart';

abstract interface class ImagePickerClient {
  Future<XFile?> pickGalleryImage();
}

class DeviceImagePickerClient implements ImagePickerClient {
  DeviceImagePickerClient({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickGalleryImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 82,
      requestFullMetadata: false,
    );
  }
}

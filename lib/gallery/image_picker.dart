import 'dart:io';
import 'package:image_picker/image_picker.dart';

class GalleryImagePicker {
  static final ImagePicker _picker = ImagePicker();

  /// 📥 Pick image from gallery
  static Future<File?> pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('❌ Failed to pick image from gallery: $e');
    }
    return null;
  }

  /// 📷 Capture image using camera
  static Future<File?> pickFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      print('❌ Failed to capture image with camera: $e');
    }
    return null;
  }
}

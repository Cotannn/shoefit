import 'package:image_picker/image_picker.dart';

class StorageService {
  Future<String> uploadProductImage(XFile file) async {
    throw Exception(
      'The hosted API uses public image URLs. Paste an image URL instead of uploading a file.',
    );
  }
}

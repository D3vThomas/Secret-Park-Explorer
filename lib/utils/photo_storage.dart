import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> takePhoto(String title) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
        final directory = await getApplicationDocumentsDirectory();
        final photoPath = '${directory.path}/$title.jpg';
        File(photo.path).copy(photoPath);
        return photoPath;
    }
    return null;
}

void savePhotoPath(Map<String, String> photoPaths, String title, String path) {
    photoPaths[title] = path;
}

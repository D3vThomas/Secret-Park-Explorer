import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> takePhoto(String title) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch; // nom unique
        final photoPath = '${directory.path}/$title-$timestamp.jpg';
        await File(photo.path).copy(photoPath);
        return photoPath;
    }
    return null;
}

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageProcessingService {
  Future<File> enhanceImage(File imageFile) async {
    // قراءة الصورة
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) throw Exception('Failed to load image');

    // تحسين التباين
    img.Image enhancedImage = img.contrast(image, 150) as img.Image;

    // تحويل الصورة إلى اللونين الأبيض والأسود
    img.Image grayscaleImage = img.grayscale(enhancedImage);

    // حفظ الصورة المعالجة
    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.png';
    File enhancedImageFile = File(tempPath);
    await enhancedImageFile.writeAsBytes(img.encodePng(grayscaleImage));

    return enhancedImageFile;
  }

  Future<File> straightenDocument(File imageFile) async {
    // قراءة الصورة
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());

    if (image == null) throw Exception('Failed to load image');

    // تدوير الصورة بزاوية ثابتة كمثال
    img.Image rotatedImage = img.copyRotate(image, 5) as img.Image;

    // حفظ الصورة المعالجة
    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/straightened_${DateTime.now().millisecondsSinceEpoch}.png';
    File straightenedImageFile = File(tempPath);
    await straightenedImageFile.writeAsBytes(img.encodePng(rotatedImage));

    return straightenedImageFile;
  }
}

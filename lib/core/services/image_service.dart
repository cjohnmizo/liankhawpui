import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image != null ? File(image.path) : null;
  }

  /// Compress image to target size (~40kb)
  /// Uses iterative quality adjustment to reach target file size
  Future<Uint8List?> compressImageToTargetSize(
    File imageFile, {
    int targetSizeKb = 40,
    int maxIterations = 10,
  }) async {
    try {
      final int targetBytes = targetSizeKb * 1024;

      // Start with a reasonable quality
      int quality = 85;
      int minQuality = 10;
      int maxQuality = 95;

      Uint8List? compressedData;

      for (int i = 0; i < maxIterations; i++) {
        compressedData = await FlutterImageCompress.compressWithFile(
          imageFile.absolute.path,
          quality: quality,
          format: CompressFormat.jpeg,
          minWidth: 800,
          minHeight: 800,
        );

        if (compressedData == null) return null;

        final int currentSize = compressedData.length;

        // If we're within 10% of target, we're good
        if (currentSize <= targetBytes * 1.1 &&
            currentSize >= targetBytes * 0.8) {
          break;
        }

        // Adjust quality based on current size
        if (currentSize > targetBytes) {
          maxQuality = quality;
          quality = ((quality + minQuality) / 2).round();
        } else {
          minQuality = quality;
          quality = ((quality + maxQuality) / 2).round();
        }

        // Prevent infinite loop
        if (maxQuality - minQuality <= 1) break;
      }

      return compressedData;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Get MIME type of file
  String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  /// Get file size in KB
  double getFileSizeInKb(Uint8List data) {
    return data.length / 1024;
  }
}

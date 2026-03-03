import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery({bool lowDataMode = false}) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: lowDataMode ? 70 : 88,
      maxWidth: lowDataMode ? 1280 : 2048,
      maxHeight: lowDataMode ? 1280 : 2048,
    );
    return image != null ? File(image.path) : null;
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera({bool lowDataMode = false}) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: lowDataMode ? 68 : 85,
      maxWidth: lowDataMode ? 1280 : 1920,
      maxHeight: lowDataMode ? 1280 : 1920,
    );
    return image != null ? File(image.path) : null;
  }

  /// Compress image to target size (~40kb)
  /// Uses iterative quality adjustment to reach target file size
  Future<Uint8List?> compressImageToTargetSize(
    File imageFile, {
    int targetSizeKb = 40,
    int maxIterations = 10,
    int minWidth = 800,
    int minHeight = 800,
    int initialQuality = 85,
  }) async {
    try {
      final int targetBytes = targetSizeKb * 1024;

      // Start with a reasonable quality
      int minQuality = 10;
      int maxQuality = 95;
      int quality = initialQuality.clamp(minQuality, maxQuality).toInt();

      Uint8List? compressedData;

      for (int i = 0; i < maxIterations; i++) {
        compressedData = await FlutterImageCompress.compressWithFile(
          imageFile.absolute.path,
          quality: quality,
          format: CompressFormat.jpeg,
          minWidth: minWidth,
          minHeight: minHeight,
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

  /// Network profile helper for poor connectivity scenarios.
  Future<Uint8List?> compressForUpload(
    File imageFile, {
    required bool lowDataMode,
  }) {
    return compressImageToTargetSize(
      imageFile,
      targetSizeKb: lowDataMode ? 28 : 50,
      minWidth: lowDataMode ? 640 : 900,
      minHeight: lowDataMode ? 640 : 900,
      initialQuality: lowDataMode ? 70 : 84,
    );
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

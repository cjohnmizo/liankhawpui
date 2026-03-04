import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

enum MediaPreset {
  postFull,
  postThumb,
  lowDataPostFull,
  lowDataPostThumb,
  avatar,
}

class ProcessedImage {
  final Uint8List bytes;
  final String contentType;
  final int sizeBytes;
  final int? width;
  final int? height;

  const ProcessedImage({
    required this.bytes,
    required this.contentType,
    required this.sizeBytes,
    this.width,
    this.height,
  });
}

class _PresetSpec {
  final int maxWidth;
  final int qualityStart;
  final int minTargetBytes;
  final int maxTargetBytes;
  final bool fixedSquare;

  const _PresetSpec({
    required this.maxWidth,
    required this.qualityStart,
    required this.minTargetBytes,
    required this.maxTargetBytes,
    this.fixedSquare = false,
  });
}

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery({bool lowDataMode = false}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera({bool lowDataMode = false}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image != null ? File(image.path) : null;
  }

  Future<ProcessedImage> processImage(
    File input, {
    required MediaPreset preset,
  }) async {
    final spec = _specForPreset(preset);
    return _compressWithPreferredFormat(input, spec);
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
      final spec = _PresetSpec(
        maxWidth: max(minWidth, minHeight),
        qualityStart: initialQuality,
        minTargetBytes: (targetBytes * 0.8).round(),
        maxTargetBytes: (targetBytes * 1.1).round(),
      );
      final result = await _compressWithPreferredFormat(
        imageFile,
        spec,
        maxIterations: maxIterations,
      );
      return result.bytes;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Network profile helper for poor connectivity scenarios.
  Future<Uint8List?> compressForUpload(
    File imageFile, {
    required bool lowDataMode,
  }) async {
    final preset = lowDataMode
        ? MediaPreset.lowDataPostFull
        : MediaPreset.postFull;
    final processed = await processImage(imageFile, preset: preset);
    return processed.bytes;
  }

  /// Get MIME type of file
  String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  /// Get file size in KB
  double getFileSizeInKb(Uint8List data) {
    return data.length / 1024;
  }

  _PresetSpec _specForPreset(MediaPreset preset) {
    switch (preset) {
      case MediaPreset.postFull:
        return const _PresetSpec(
          maxWidth: 1200,
          qualityStart: 80,
          minTargetBytes: 150 * 1024,
          maxTargetBytes: 300 * 1024,
        );
      case MediaPreset.postThumb:
        return const _PresetSpec(
          maxWidth: 600,
          qualityStart: 75,
          minTargetBytes: 50 * 1024,
          maxTargetBytes: 100 * 1024,
        );
      case MediaPreset.lowDataPostFull:
        return const _PresetSpec(
          maxWidth: 900,
          qualityStart: 70,
          minTargetBytes: 80 * 1024,
          maxTargetBytes: 150 * 1024,
        );
      case MediaPreset.lowDataPostThumb:
        return const _PresetSpec(
          maxWidth: 450,
          qualityStart: 65,
          minTargetBytes: 30 * 1024,
          maxTargetBytes: 60 * 1024,
        );
      case MediaPreset.avatar:
        return const _PresetSpec(
          maxWidth: 256,
          qualityStart: 80,
          minTargetBytes: 30 * 1024,
          maxTargetBytes: 80 * 1024,
          fixedSquare: true,
        );
    }
  }

  Future<ProcessedImage> _compressWithPreferredFormat(
    File input,
    _PresetSpec spec, {
    int maxIterations = 12,
  }) async {
    try {
      final webp = await _compressToRange(
        input,
        spec,
        format: CompressFormat.webp,
        contentType: 'image/webp',
        maxIterations: maxIterations,
      );
      if (webp != null) return webp;
    } catch (_) {
      // Fallback to JPEG below.
    }

    final jpeg = await _compressToRange(
      input,
      spec,
      format: CompressFormat.jpeg,
      contentType: 'image/jpeg',
      maxIterations: maxIterations,
    );
    if (jpeg == null) {
      throw Exception('Unable to process image in WebP or JPEG format');
    }
    return jpeg;
  }

  Future<ProcessedImage?> _compressToRange(
    File input,
    _PresetSpec spec, {
    required CompressFormat format,
    required String contentType,
    required int maxIterations,
  }) async {
    int quality = spec.qualityStart.clamp(25, 95).toInt();
    int width = spec.maxWidth;
    Uint8List? lastBytes;

    for (int i = 0; i < maxIterations; i++) {
      final compressed = await FlutterImageCompress.compressWithFile(
        input.absolute.path,
        quality: quality,
        format: format,
        minWidth: width,
        minHeight: spec.fixedSquare ? width : width,
        autoCorrectionAngle: true,
        keepExif: false,
        numberOfRetries: 1,
      );

      if (compressed == null || compressed.isEmpty) {
        continue;
      }

      lastBytes = compressed;
      final size = compressed.length;
      final inRange =
          size >= spec.minTargetBytes && size <= spec.maxTargetBytes;
      if (inRange) {
        return ProcessedImage(
          bytes: compressed,
          contentType: contentType,
          sizeBytes: size,
        );
      }

      final previousQuality = quality;
      final previousWidth = width;
      if (size > spec.maxTargetBytes) {
        if (quality > 42) {
          quality = max(28, quality - 8);
        } else if (!spec.fixedSquare && width > 256) {
          width = max(256, (width * 0.9).round());
        }
      } else if (size < spec.minTargetBytes) {
        quality = min(95, quality + 6);
      }

      if (quality == previousQuality && width == previousWidth) {
        break;
      }
    }

    if (lastBytes == null) return null;
    return ProcessedImage(
      bytes: lastBytes,
      contentType: contentType,
      sizeBytes: lastBytes.length,
    );
  }
}

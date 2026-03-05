import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

enum MediaPreset {
  postFull,
  postThumb,
  lowDataPostFull,
  lowDataPostThumb,
  story,
  lowDataStory,
  avatar,
  lowDataAvatar,
  ngoLogo,
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
  final int? maxHeight;
  final int qualityStart;
  final int minTargetBytes;
  final int maxTargetBytes;
  final double? cropAspectRatio;
  final bool keepPngIfTransparent;

  const _PresetSpec({
    required this.maxWidth,
    this.maxHeight,
    required this.qualityStart,
    required this.minTargetBytes,
    required this.maxTargetBytes,
    this.cropAspectRatio,
    this.keepPngIfTransparent = false,
  });
}

class _ImageDimensions {
  final int width;
  final int height;

  const _ImageDimensions({required this.width, required this.height});
}

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery({bool lowDataMode = false}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image != null ? File(image.path) : null;
  }

  Future<File?> pickImageFromCamera({bool lowDataMode = false}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    return image != null ? File(image.path) : null;
  }

  Future<ProcessedImage> processImage(
    File input, {
    required MediaPreset preset,
  }) async {
    final spec = _specForPreset(preset);
    final sourceBytes = await input.readAsBytes();
    final normalizedBytes = await _normalizeInputBytes(sourceBytes, spec);
    return _compressWithPreferredFormat(normalizedBytes, spec);
  }

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
        maxHeight: max(minWidth, minHeight),
        qualityStart: initialQuality,
        minTargetBytes: (targetBytes * 0.8).round(),
        maxTargetBytes: (targetBytes * 1.1).round(),
      );

      final normalizedBytes = await imageFile.readAsBytes();
      final result = await _compressWithPreferredFormat(
        normalizedBytes,
        spec,
        maxIterations: maxIterations,
      );
      return result.bytes;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

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

  String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  double getFileSizeInKb(Uint8List data) {
    return data.length / 1024;
  }

  _PresetSpec _specForPreset(MediaPreset preset) {
    switch (preset) {
      case MediaPreset.postFull:
        return const _PresetSpec(
          maxWidth: 1200,
          qualityStart: 78,
          minTargetBytes: 150 * 1024,
          maxTargetBytes: 300 * 1024,
        );
      case MediaPreset.postThumb:
        return const _PresetSpec(
          maxWidth: 600,
          qualityStart: 74,
          minTargetBytes: 50 * 1024,
          maxTargetBytes: 100 * 1024,
        );
      case MediaPreset.lowDataPostFull:
        return const _PresetSpec(
          maxWidth: 900,
          qualityStart: 68,
          minTargetBytes: 80 * 1024,
          maxTargetBytes: 150 * 1024,
        );
      case MediaPreset.lowDataPostThumb:
        return const _PresetSpec(
          maxWidth: 450,
          qualityStart: 62,
          minTargetBytes: 30 * 1024,
          maxTargetBytes: 60 * 1024,
        );
      case MediaPreset.story:
        return const _PresetSpec(
          maxWidth: 1080,
          maxHeight: 1920,
          qualityStart: 75,
          minTargetBytes: 200 * 1024,
          maxTargetBytes: 400 * 1024,
          cropAspectRatio: 1080 / 1920,
        );
      case MediaPreset.lowDataStory:
        return const _PresetSpec(
          maxWidth: 720,
          maxHeight: 1280,
          qualityStart: 65,
          minTargetBytes: 120 * 1024,
          maxTargetBytes: 250 * 1024,
          cropAspectRatio: 720 / 1280,
        );
      case MediaPreset.avatar:
        return const _PresetSpec(
          maxWidth: 256,
          maxHeight: 256,
          qualityStart: 80,
          minTargetBytes: 30 * 1024,
          maxTargetBytes: 80 * 1024,
          cropAspectRatio: 1,
        );
      case MediaPreset.lowDataAvatar:
        return const _PresetSpec(
          maxWidth: 192,
          maxHeight: 192,
          qualityStart: 70,
          minTargetBytes: 20 * 1024,
          maxTargetBytes: 50 * 1024,
          cropAspectRatio: 1,
        );
      case MediaPreset.ngoLogo:
        return const _PresetSpec(
          maxWidth: 512,
          maxHeight: 512,
          qualityStart: 76,
          minTargetBytes: 50 * 1024,
          maxTargetBytes: 120 * 1024,
          cropAspectRatio: 1,
          keepPngIfTransparent: true,
        );
    }
  }

  Future<Uint8List> _normalizeInputBytes(
    Uint8List sourceBytes,
    _PresetSpec spec,
  ) async {
    final aspectRatio = spec.cropAspectRatio;
    if (aspectRatio == null) return sourceBytes;

    try {
      return await _cropCenterToAspectRatio(sourceBytes, aspectRatio);
    } catch (_) {
      return sourceBytes;
    }
  }

  Future<ProcessedImage> _compressWithPreferredFormat(
    Uint8List sourceBytes,
    _PresetSpec spec, {
    int maxIterations = 12,
  }) async {
    final keepPng = spec.keepPngIfTransparent
        ? await _hasTransparency(sourceBytes)
        : false;

    try {
      final webp = await _compressToRange(
        sourceBytes,
        spec,
        format: CompressFormat.webp,
        contentType: 'image/webp',
        maxIterations: maxIterations,
      );
      if (webp != null) return webp;
    } catch (_) {
      // Continue with fallback formats.
    }

    if (keepPng) {
      final png = await _compressToRange(
        sourceBytes,
        spec,
        format: CompressFormat.png,
        contentType: 'image/png',
        maxIterations: maxIterations,
      );
      if (png != null) return png;
    }

    final jpeg = await _compressToRange(
      sourceBytes,
      spec,
      format: CompressFormat.jpeg,
      contentType: 'image/jpeg',
      maxIterations: maxIterations,
    );
    if (jpeg == null) {
      throw Exception('Unable to process image in WebP/JPEG fallback pipeline');
    }
    return jpeg;
  }

  Future<ProcessedImage?> _compressToRange(
    Uint8List sourceBytes,
    _PresetSpec spec, {
    required CompressFormat format,
    required String contentType,
    required int maxIterations,
  }) async {
    final sourceDimensions = await _decodeImageDimensions(sourceBytes);
    final targetAspect = spec.maxHeight != null
        ? spec.maxWidth / spec.maxHeight!
        : sourceDimensions != null
        ? sourceDimensions.width / sourceDimensions.height
        : 1.0;

    var quality = spec.qualityStart.clamp(25, 95);
    var width = spec.maxWidth;
    var height = spec.maxHeight ?? max(1, (width / targetAspect).round());

    Uint8List? lastBytes;

    for (var i = 0; i < maxIterations; i++) {
      final compressed = await FlutterImageCompress.compressWithList(
        sourceBytes,
        quality: quality,
        format: format,
        minWidth: width,
        minHeight: height,
        autoCorrectionAngle: true,
        keepExif: false,
      );

      if (compressed.isEmpty) {
        continue;
      }

      lastBytes = Uint8List.fromList(compressed);
      final size = lastBytes.length;
      final inRange =
          size >= spec.minTargetBytes && size <= spec.maxTargetBytes;
      if (inRange) {
        final dimensions = await _decodeImageDimensions(lastBytes);
        return ProcessedImage(
          bytes: lastBytes,
          contentType: contentType,
          sizeBytes: size,
          width: dimensions?.width,
          height: dimensions?.height,
        );
      }

      final previousQuality = quality;
      final previousWidth = width;
      final previousHeight = height;

      if (size > spec.maxTargetBytes) {
        if (quality > 42) {
          quality = max(25, quality - 8);
        } else {
          width = max(128, (width * 0.9).round());
          height = max(128, (height * 0.9).round());
        }
      } else {
        if (quality < 92) {
          quality = min(95, quality + 6);
        } else if (width < spec.maxWidth) {
          width = min(spec.maxWidth, (width * 1.05).round());
          height = min(
            spec.maxHeight ?? 4096,
            max(1, (width / targetAspect).round()),
          );
        }
      }

      if (quality == previousQuality &&
          width == previousWidth &&
          height == previousHeight) {
        break;
      }
    }

    if (lastBytes == null) return null;
    final fallbackDimensions = await _decodeImageDimensions(lastBytes);
    return ProcessedImage(
      bytes: lastBytes,
      contentType: contentType,
      sizeBytes: lastBytes.length,
      width: fallbackDimensions?.width,
      height: fallbackDimensions?.height,
    );
  }

  Future<Uint8List> _cropCenterToAspectRatio(
    Uint8List bytes,
    double targetAspectRatio,
  ) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final srcWidth = image.width.toDouble();
    final srcHeight = image.height.toDouble();
    final srcAspect = srcWidth / srcHeight;

    double cropWidth = srcWidth;
    double cropHeight = srcHeight;
    if (srcAspect > targetAspectRatio) {
      cropWidth = srcHeight * targetAspectRatio;
    } else {
      cropHeight = srcWidth / targetAspectRatio;
    }

    final srcRect = ui.Rect.fromLTWH(
      (srcWidth - cropWidth) / 2,
      (srcHeight - cropHeight) / 2,
      cropWidth,
      cropHeight,
    );

    final outWidth = max(1, cropWidth.round());
    final outHeight = max(1, cropHeight.round());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final dstRect = ui.Rect.fromLTWH(
      0,
      0,
      outWidth.toDouble(),
      outHeight.toDouble(),
    );
    canvas.drawImageRect(image, srcRect, dstRect, ui.Paint());
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(outWidth, outHeight);
    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception('Failed to crop image');
    }
    return byteData.buffer.asUint8List();
  }

  Future<_ImageDimensions?> _decodeImageDimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return _ImageDimensions(
        width: frame.image.width,
        height: frame.image.height,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _hasTransparency(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final rgba = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (rgba == null) return false;
      final list = rgba.buffer.asUint8List();
      for (var i = 3; i < list.length; i += 4) {
        if (list[i] < 255) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

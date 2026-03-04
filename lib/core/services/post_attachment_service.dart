import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:liankhawpui/core/services/image_service.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum PostAttachmentType { image, document }

class PostAttachmentUploadResult {
  final PostAttachmentType type;
  final String fileName;
  final int sizeBytes;
  final String publicUrl;
  final String objectPath;
  final String contentType;
  final String? thumbObjectPath;
  final String? thumbPublicUrl;
  final String? thumbContentType;

  const PostAttachmentUploadResult({
    required this.type,
    required this.fileName,
    required this.sizeBytes,
    required this.publicUrl,
    required this.objectPath,
    required this.contentType,
    this.thumbObjectPath,
    this.thumbPublicUrl,
    this.thumbContentType,
  });

  String? get preferredListImageUrl => thumbPublicUrl ?? publicUrl;

  String toMarkdown() {
    final label = _escapeMarkdown(fileName);
    if (type == PostAttachmentType.image) {
      final imageHref = publicUrl.trim().isNotEmpty ? publicUrl : objectPath;
      return '![$label]($imageHref)';
    }
    return '[$label]($publicUrl)';
  }

  String _escapeMarkdown(String value) {
    return value.replaceAll('[', '').replaceAll(']', '').trim();
  }
}

class _UploadObject {
  final String objectPath;
  final String? publicUrl;

  const _UploadObject({required this.objectPath, this.publicUrl});
}

class PostAttachmentService {
  static const String bucketName = 'post-attachments';
  static const int maxDocumentBytes = 5 * 1024 * 1024;
  static const List<String> allowedDocumentExtensions = <String>[
    'pdf',
    'doc',
    'docx',
    'txt',
  ];
  static const String _postImageFolder = 'post-images';
  static const String _postThumbFolder = 'post-thumbs';

  static const String _thumbCacheControl =
      'public, max-age=31536000, immutable';
  static const String _fullImageCacheControl = 'public, max-age=604800';
  static const String _documentCacheControl = 'private, max-age=3600';

  final ImageService _imageService;
  final Uuid _uuid;

  PostAttachmentService({ImageService? imageService, Uuid? uuid})
    : _imageService = imageService ?? ImageService(),
      _uuid = uuid ?? const Uuid();

  Future<PostAttachmentUploadResult?> pickCompressAndUploadImage({
    required String folder,
    required bool lowDataMode,
  }) async {
    // Retained for backward compatibility; image uploads now use fixed folders.
    final _ = folder;
    final imageFile = await _imageService.pickImageFromGallery(
      lowDataMode: lowDataMode,
    );
    if (imageFile == null) return null;

    final fullPreset = lowDataMode
        ? MediaPreset.lowDataPostFull
        : MediaPreset.postFull;
    final thumbPreset = lowDataMode
        ? MediaPreset.lowDataPostThumb
        : MediaPreset.postThumb;

    final processedFull = await _imageService.processImage(
      imageFile,
      preset: fullPreset,
    );
    final processedThumb = await _imageService.processImage(
      imageFile,
      preset: thumbPreset,
    );

    final baseName = _buildObjectBaseName();
    final fullExtension = _extensionForContentType(processedFull.contentType);
    final thumbExtension = _extensionForContentType(processedThumb.contentType);
    final fullFileName = '$baseName$fullExtension';
    final thumbFileName = '${baseName}_thumb$thumbExtension';

    final fullUpload = await _uploadBytes(
      bytes: processedFull.bytes,
      folder: _postImageFolder,
      objectFileName: fullFileName,
      contentType: processedFull.contentType,
      cacheControl: _fullImageCacheControl,
      generatePublicUrl: true,
    );
    final thumbUpload = await _uploadBytes(
      bytes: processedThumb.bytes,
      folder: _postThumbFolder,
      objectFileName: thumbFileName,
      contentType: processedThumb.contentType,
      cacheControl: _thumbCacheControl,
      generatePublicUrl: true,
    );

    return PostAttachmentUploadResult(
      type: PostAttachmentType.image,
      fileName: fullFileName,
      sizeBytes: processedFull.sizeBytes,
      publicUrl: fullUpload.publicUrl ?? '',
      objectPath: fullUpload.objectPath,
      contentType: processedFull.contentType,
      thumbObjectPath: thumbUpload.objectPath,
      thumbPublicUrl: thumbUpload.publicUrl,
      thumbContentType: processedThumb.contentType,
    );
  }

  Future<PostAttachmentUploadResult?> pickAndUploadDocument({
    required String folder,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: allowedDocumentExtensions,
      withData: kIsWeb,
    );
    if (picked == null || picked.files.isEmpty) return null;

    final file = picked.files.single;
    final extension = p
        .extension(file.name)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!allowedDocumentExtensions.contains(extension)) {
      throw Exception(
        'Unsupported document type. Allowed: ${allowedDocumentExtensions.join(', ')}',
      );
    }

    final bytes = await _readPlatformFileBytes(file);
    if (bytes.length > maxDocumentBytes) {
      throw Exception(
        'Document is ${_toKb(bytes.length)} KB. Max allowed is 5120 KB.',
      );
    }

    final contentType =
        lookupMimeType(file.name, headerBytes: bytes.take(16).toList()) ??
        _guessDocContentType(extension);

    final baseName = _buildObjectBaseName();
    final objectFileName = '$baseName.${extension.toLowerCase()}';
    final upload = await _uploadBytes(
      bytes: bytes,
      folder: folder,
      objectFileName: objectFileName,
      contentType: contentType,
      cacheControl: _documentCacheControl,
      generatePublicUrl: true,
    );

    return PostAttachmentUploadResult(
      type: PostAttachmentType.document,
      fileName: file.name,
      sizeBytes: bytes.length,
      publicUrl: upload.publicUrl ?? '',
      objectPath: upload.objectPath,
      contentType: contentType,
    );
  }

  Future<_UploadObject> _uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String objectFileName,
    required String contentType,
    required String cacheControl,
    required bool generatePublicUrl,
  }) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sign in required before uploading attachments.');
    }

    final cleanFolder = _sanitizePathSegment(folder);
    final fileName = _sanitizeFileName(objectFileName);
    final objectPath = '$userId/$cleanFolder/$fileName';

    try {
      await SupabaseService.client.storage
          .from(bucketName)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
              cacheControl: cacheControl,
            ),
          );
      final publicUrl = generatePublicUrl
          ? SupabaseService.client.storage
                .from(bucketName)
                .getPublicUrl(objectPath)
          : null;
      return _UploadObject(objectPath: objectPath, publicUrl: publicUrl);
    } on StorageException catch (error) {
      throw Exception('Attachment upload failed: ${error.message}');
    }
  }

  Future<Uint8List> _readPlatformFileBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes!;
    }
    final path = file.path;
    if (path == null || path.isEmpty) {
      throw Exception('Selected document could not be read.');
    }
    return File(path).readAsBytes();
  }

  String _guessDocContentType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String _extensionForContentType(String contentType) {
    final value = contentType.toLowerCase();
    if (value.contains('webp')) return '.webp';
    if (value.contains('jpeg') || value.contains('jpg')) return '.jpg';
    if (value.contains('png')) return '.png';
    return '.bin';
  }

  String _buildObjectBaseName() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
  }

  String _sanitizeFileName(String value) {
    final extension = p.extension(value).toLowerCase();
    final base = p
        .basenameWithoutExtension(value)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final safeBase = base.isEmpty ? _buildObjectBaseName() : base;
    return '$safeBase$extension';
  }

  String _sanitizePathSegment(String value) {
    final cleaned = value.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9_-]+'),
      '-',
    );
    if (cleaned.isEmpty) return 'posts';
    return cleaned;
  }

  String _toKb(int bytes) => (bytes / 1024).toStringAsFixed(1);
}

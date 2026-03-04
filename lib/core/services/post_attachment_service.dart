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

  const PostAttachmentUploadResult({
    required this.type,
    required this.fileName,
    required this.sizeBytes,
    required this.publicUrl,
  });

  String toMarkdown() {
    final label = _escapeMarkdown(fileName);
    if (type == PostAttachmentType.image) {
      return '![$label]($publicUrl)';
    }
    return '[$label]($publicUrl)';
  }

  String _escapeMarkdown(String value) {
    return value.replaceAll('[', '').replaceAll(']', '').trim();
  }
}

class PostAttachmentService {
  static const String bucketName = 'post-attachments';
  static const int maxImageBytes = 40 * 1024;
  static const int maxDocumentBytes = 70 * 1024;
  static const List<String> allowedDocumentExtensions = <String>[
    'pdf',
    'doc',
    'docx',
    'txt',
  ];

  final ImageService _imageService;
  final Uuid _uuid;

  PostAttachmentService({ImageService? imageService, Uuid? uuid})
    : _imageService = imageService ?? ImageService(),
      _uuid = uuid ?? const Uuid();

  Future<PostAttachmentUploadResult?> pickCompressAndUploadImage({
    required String folder,
    required bool lowDataMode,
  }) async {
    final imageFile = await _imageService.pickImageFromGallery(
      lowDataMode: lowDataMode,
    );
    if (imageFile == null) return null;

    final compressedData = await _imageService.compressImageToTargetSize(
      imageFile,
      targetSizeKb: 40,
      minWidth: lowDataMode ? 540 : 720,
      minHeight: lowDataMode ? 540 : 720,
      initialQuality: lowDataMode ? 62 : 72,
      maxIterations: 12,
    );
    if (compressedData == null) {
      throw Exception('Failed to compress image');
    }

    if (compressedData.length > maxImageBytes) {
      throw Exception(
        'Image is ${_toKb(compressedData.length)} KB after compression. '
        'Choose a simpler image (limit: 40 KB).',
      );
    }

    return _uploadBytes(
      bytes: compressedData,
      type: PostAttachmentType.image,
      folder: folder,
      fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      contentType: 'image/jpeg',
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
        'Document is ${_toKb(bytes.length)} KB. Max allowed is 70 KB.',
      );
    }

    final contentType =
        lookupMimeType(file.name, headerBytes: bytes.take(16).toList()) ??
        _guessDocContentType(extension);

    return _uploadBytes(
      bytes: bytes,
      type: PostAttachmentType.document,
      folder: folder,
      fileName: file.name,
      contentType: contentType,
    );
  }

  Future<PostAttachmentUploadResult> _uploadBytes({
    required Uint8List bytes,
    required PostAttachmentType type,
    required String folder,
    required String fileName,
    required String contentType,
  }) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sign in required before uploading attachments.');
    }

    final cleanFolder = _sanitizePathSegment(folder);
    final ext = p.extension(fileName).toLowerCase();
    final objectPath =
        '$userId/$cleanFolder/${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}$ext';

    try {
      await SupabaseService.client.storage
          .from(bucketName)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      final publicUrl = SupabaseService.client.storage
          .from(bucketName)
          .getPublicUrl(objectPath);

      return PostAttachmentUploadResult(
        type: type,
        fileName: fileName,
        sizeBytes: bytes.length,
        publicUrl: publicUrl,
      );
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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:liankhawpui/core/services/image_service.dart';
import 'package:liankhawpui/core/services/storage_budget_service.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const String kPostAttachmentImageBucket = 'post-attachments';
const String kPostAttachmentDocumentBucket = 'post-documents';

enum PostAttachmentType { image, document }

class ImageUploadPreviewData {
  final String originalFileName;
  final int originalSizeBytes;
  final ProcessedImage fullImage;
  final ProcessedImage thumbImage;
  final bool lowDataMode;

  const ImageUploadPreviewData({
    required this.originalFileName,
    required this.originalSizeBytes,
    required this.fullImage,
    required this.thumbImage,
    required this.lowDataMode,
  });

  int get estimatedStoredBytes => fullImage.sizeBytes + thumbImage.sizeBytes;
}

class PostAttachmentUploadResult {
  final PostAttachmentType type;
  final String fileName;
  final int sizeBytes;
  final String publicUrl;
  final String objectPath;
  final String contentType;
  final String? originalFileName;
  final int? originalSizeBytes;
  final int? width;
  final int? height;
  final int? thumbSizeBytes;
  final int? thumbWidth;
  final int? thumbHeight;
  final int? totalStoredBytes;
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
    this.originalFileName,
    this.originalSizeBytes,
    this.width,
    this.height,
    this.thumbSizeBytes,
    this.thumbWidth,
    this.thumbHeight,
    this.totalStoredBytes,
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
    return '[$label](${encodePrivateDocumentHref(objectPath)})';
  }

  static String encodePrivateDocumentHref(
    String objectPath, {
    String bucketName = kPostAttachmentDocumentBucket,
  }) {
    return 'lpdoc://attachment?bucket=${Uri.encodeComponent(bucketName)}&path=${Uri.encodeComponent(objectPath)}';
  }

  static String? decodePrivateDocumentPath(String href) {
    final uri = Uri.tryParse(href);
    if (uri == null || uri.scheme != 'lpdoc') return null;
    final encodedPath = uri.queryParameters['path'];
    if (encodedPath == null || encodedPath.trim().isEmpty) return null;
    return Uri.decodeComponent(encodedPath);
  }

  static String? decodePrivateDocumentBucket(String href) {
    final uri = Uri.tryParse(href);
    if (uri == null || uri.scheme != 'lpdoc') return null;
    final encodedBucket = uri.queryParameters['bucket'];
    if (encodedBucket == null || encodedBucket.trim().isEmpty) return null;
    return Uri.decodeComponent(encodedBucket);
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

class _PrivateDocumentTarget {
  final String bucketName;
  final String objectPath;

  const _PrivateDocumentTarget({
    required this.bucketName,
    required this.objectPath,
  });
}

class PostAttachmentService {
  static const String bucketName = kPostAttachmentImageBucket;
  static const String documentBucketName = kPostAttachmentDocumentBucket;
  static const int maxImageInputBytes = 15 * 1024 * 1024;
  static const int maxDocumentBytes = 5 * 1024 * 1024;
  static const List<String> allowedDocumentExtensions = <String>[
    'pdf',
    'docx',
    'xlsx',
  ];
  static const String _postImageFolder = 'post-images';
  static const String _postThumbFolder = 'post-thumbs';

  static const String _thumbCacheControl =
      'public, max-age=31536000, immutable';
  static const String _fullImageCacheControl = 'public, max-age=604800';
  static const String _documentCacheControl = 'private, max-age=3600';

  final ImageService _imageService;
  final StorageBudgetService _storageBudgetService;
  final Uuid _uuid;

  PostAttachmentService({
    ImageService? imageService,
    StorageBudgetService? storageBudgetService,
    Uuid? uuid,
  }) : _imageService = imageService ?? ImageService(),
       _storageBudgetService = storageBudgetService ?? StorageBudgetService(),
       _uuid = uuid ?? const Uuid();

  Future<PostAttachmentUploadResult?> pickCompressAndUploadImage({
    required String folder,
    required bool lowDataMode,
    Future<bool> Function(ImageUploadPreviewData preview)? confirmUpload,
  }) async {
    _assertNoUrlInput(folder);
    // Retained for backward compatibility; image uploads now use fixed folders.
    final _ = folder;
    final imageFile = await _imageService.pickImageFromGallery(
      lowDataMode: lowDataMode,
    );
    if (imageFile == null) return null;
    final originalSize = await imageFile.length();
    if (originalSize > maxImageInputBytes) {
      throw Exception(
        'Image is too large (${humanReadableBytes(originalSize)}). '
        'Please pick an image under ${humanReadableBytes(maxImageInputBytes)}.',
      );
    }

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
    final preview = ImageUploadPreviewData(
      originalFileName: p.basename(imageFile.path),
      originalSizeBytes: originalSize,
      fullImage: processedFull,
      thumbImage: processedThumb,
      lowDataMode: lowDataMode,
    );

    if (confirmUpload != null) {
      final shouldContinue = await confirmUpload(preview);
      if (!shouldContinue) return null;
    }

    final baseName = _buildObjectBaseName();
    final fullExtension = _extensionForContentType(processedFull.contentType);
    final thumbExtension = _extensionForContentType(processedThumb.contentType);
    final fullFileName = '$baseName$fullExtension';
    final thumbFileName = '${baseName}_thumb$thumbExtension';

    final fullUpload = await _uploadBytes(
      bucketName: bucketName,
      bytes: processedFull.bytes,
      folder: _postImageFolder,
      objectFileName: fullFileName,
      contentType: processedFull.contentType,
      cacheControl: _fullImageCacheControl,
      generatePublicUrl: true,
    );
    final thumbUpload = await _uploadBytes(
      bucketName: bucketName,
      bytes: processedThumb.bytes,
      folder: _postThumbFolder,
      objectFileName: thumbFileName,
      contentType: processedThumb.contentType,
      cacheControl: _thumbCacheControl,
      generatePublicUrl: true,
    );
    await _storageBudgetService.recordEntries([
      MediaBudgetEntry(
        objectPath: fullUpload.objectPath,
        mimeType: processedFull.contentType,
        sizeBytes: processedFull.sizeBytes,
        kind: MediaBudgetKind.image,
        width: processedFull.width,
        height: processedFull.height,
        originalFileName: preview.originalFileName,
      ),
      MediaBudgetEntry(
        objectPath: thumbUpload.objectPath,
        mimeType: processedThumb.contentType,
        sizeBytes: processedThumb.sizeBytes,
        kind: MediaBudgetKind.thumb,
        width: processedThumb.width,
        height: processedThumb.height,
        originalFileName: preview.originalFileName,
      ),
    ]);

    return PostAttachmentUploadResult(
      type: PostAttachmentType.image,
      fileName: fullFileName,
      sizeBytes: processedFull.sizeBytes,
      publicUrl: fullUpload.publicUrl ?? '',
      objectPath: fullUpload.objectPath,
      contentType: processedFull.contentType,
      originalFileName: preview.originalFileName,
      originalSizeBytes: preview.originalSizeBytes,
      width: processedFull.width,
      height: processedFull.height,
      thumbSizeBytes: processedThumb.sizeBytes,
      thumbWidth: processedThumb.width,
      thumbHeight: processedThumb.height,
      totalStoredBytes: preview.estimatedStoredBytes,
      thumbObjectPath: thumbUpload.objectPath,
      thumbPublicUrl: thumbUpload.publicUrl,
      thumbContentType: processedThumb.contentType,
    );
  }

  Future<PostAttachmentUploadResult?> pickAndUploadDocument({
    required String folder,
  }) async {
    _assertNoUrlInput(folder);
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
      throw Exception('Unsupported document type. Allowed: PDF, DOCX, XLSX.');
    }

    if (file.size > maxDocumentBytes) {
      throw Exception(
        'Document is too large (${humanReadableBytes(file.size)}). '
        'Max allowed is ${humanReadableBytes(maxDocumentBytes)}.',
      );
    }

    final bytes = await _readPlatformFileBytes(file);
    if (bytes.length > maxDocumentBytes) {
      throw Exception(
        'Document is too large (${humanReadableBytes(bytes.length)}). '
        'Max allowed is ${humanReadableBytes(maxDocumentBytes)}.',
      );
    }

    final contentType =
        lookupMimeType(file.name, headerBytes: bytes.take(16).toList()) ??
        _guessDocContentType(extension);

    final baseName = _buildObjectBaseName();
    final objectFileName = '$baseName.${extension.toLowerCase()}';
    final upload = await _uploadBytes(
      bucketName: documentBucketName,
      bytes: bytes,
      folder: folder,
      objectFileName: objectFileName,
      contentType: contentType,
      cacheControl: _documentCacheControl,
      generatePublicUrl: false,
    );
    await _storageBudgetService.recordEntries([
      MediaBudgetEntry(
        objectPath: upload.objectPath,
        mimeType: contentType,
        sizeBytes: bytes.length,
        kind: MediaBudgetKind.document,
        originalFileName: file.name,
      ),
    ]);

    return PostAttachmentUploadResult(
      type: PostAttachmentType.document,
      fileName: file.name,
      sizeBytes: bytes.length,
      publicUrl: '',
      objectPath: upload.objectPath,
      contentType: contentType,
      originalFileName: file.name,
      originalSizeBytes: bytes.length,
      totalStoredBytes: bytes.length,
    );
  }

  Future<String> createSignedUrl({
    required String objectPath,
    String bucketName = documentBucketName,
    int expiresInSeconds = 3600,
  }) async {
    final normalized = _normalizeObjectPath(objectPath);
    if (normalized.isEmpty) {
      throw Exception('Attachment path is empty');
    }
    final resolvedBucketName = _normalizeDocumentBucketName(bucketName);
    try {
      return await SupabaseService.client.storage
          .from(resolvedBucketName)
          .createSignedUrl(normalized, expiresInSeconds);
    } on StorageException catch (error) {
      throw Exception('Could not create signed URL: ${error.message}');
    }
  }

  Future<Uri?> resolveLaunchUri(
    String href, {
    int expiresInSeconds = 3600,
  }) async {
    final privateTarget = _extractPrivateDocumentTarget(href);
    if (privateTarget != null) {
      final signed = await createSignedUrl(
        objectPath: privateTarget.objectPath,
        bucketName: privateTarget.bucketName,
        expiresInSeconds: expiresInSeconds,
      );
      return Uri.tryParse(signed);
    }
    return Uri.tryParse(href);
  }

  Future<_UploadObject> _uploadBytes({
    required String bucketName,
    required Uint8List bytes,
    required String folder,
    required String objectFileName,
    required String contentType,
    required String cacheControl,
    required bool generatePublicUrl,
  }) async {
    _assertNoUrlInput(folder);
    _assertNoUrlInput(objectFileName);
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
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
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

  String _normalizeObjectPath(String objectPath) {
    var value = objectPath.trim();
    if (value.startsWith('/')) {
      value = value.substring(1);
    }
    for (final knownBucket in const <String>[bucketName, documentBucketName]) {
      if (value.startsWith('$knownBucket/')) {
        value = value.substring(knownBucket.length + 1);
      }
    }
    return value;
  }

  _PrivateDocumentTarget? _extractPrivateDocumentTarget(String href) {
    final fromCustomScheme =
        PostAttachmentUploadResult.decodePrivateDocumentPath(href);
    if (fromCustomScheme != null && fromCustomScheme.isNotEmpty) {
      final bucket = _normalizeDocumentBucketName(
        PostAttachmentUploadResult.decodePrivateDocumentBucket(href),
      );
      return _PrivateDocumentTarget(
        bucketName: bucket,
        objectPath: _normalizeObjectPath(fromCustomScheme),
      );
    }

    final uri = Uri.tryParse(href);
    if (uri == null) return null;
    final hasScheme = uri.scheme.isNotEmpty;
    if (!hasScheme && href.contains('/')) {
      final normalized = _normalizeObjectPath(href);
      if (normalized.isEmpty) return null;
      return _PrivateDocumentTarget(
        bucketName: bucketName,
        objectPath: normalized,
      );
    }
    return null;
  }

  String _normalizeDocumentBucketName(String? value) {
    final normalized = value?.trim();
    if (normalized == documentBucketName || normalized == bucketName) {
      return normalized!;
    }
    return bucketName;
  }

  static String humanReadableBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _assertNoUrlInput(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      throw Exception(
        'URL image uploads are disabled. Please pick an image from your device.',
      );
    }
  }
}

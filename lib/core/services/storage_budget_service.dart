import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int oneGigabyteBytes = 1024 * 1024 * 1024;

enum MediaBudgetKind { image, thumb, document }

class MediaBudgetEntry {
  final String objectPath;
  final String mimeType;
  final int sizeBytes;
  final MediaBudgetKind kind;
  final int? width;
  final int? height;
  final String? originalFileName;

  const MediaBudgetEntry({
    required this.objectPath,
    required this.mimeType,
    required this.sizeBytes,
    required this.kind,
    this.width,
    this.height,
    this.originalFileName,
  });

  String get dedupeKey => '${kind.name}:$objectPath';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'objectPath': objectPath,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'kind': kind.name,
    'width': width,
    'height': height,
    'originalFileName': originalFileName,
  };

  static MediaBudgetEntry? fromJson(Map<String, dynamic> json) {
    final objectPath = (json['objectPath'] as String?)?.trim();
    final mimeType = (json['mimeType'] as String?)?.trim();
    final sizeBytes = json['sizeBytes'] as int?;
    final kindRaw = (json['kind'] as String?)?.trim();
    if (objectPath == null ||
        objectPath.isEmpty ||
        mimeType == null ||
        mimeType.isEmpty ||
        sizeBytes == null ||
        sizeBytes <= 0 ||
        kindRaw == null ||
        kindRaw.isEmpty) {
      return null;
    }

    final kind = MediaBudgetKind.values.where((item) => item.name == kindRaw);
    if (kind.isEmpty) return null;
    return MediaBudgetEntry(
      objectPath: objectPath,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      kind: kind.first,
      width: json['width'] as int?,
      height: json['height'] as int?,
      originalFileName: (json['originalFileName'] as String?)?.trim(),
    );
  }
}

class StorageBudget {
  final int totalBytesUsedKnown;
  final int imagesBytes;
  final int thumbsBytes;
  final int docsBytes;

  const StorageBudget({
    required this.totalBytesUsedKnown,
    required this.imagesBytes,
    required this.thumbsBytes,
    required this.docsBytes,
  });

  double get percentOf1GB => (totalBytesUsedKnown / oneGigabyteBytes) * 100;
}

class StorageBudgetService {
  static const String _entriesKey = 'storage_budget_entries_v1';

  Future<void> recordEntries(Iterable<MediaBudgetEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _readEntries(prefs);
    for (final entry in entries) {
      existing[entry.dedupeKey] = entry;
    }
    await prefs.setString(_entriesKey, _encodeEntries(existing.values));
  }

  Future<StorageBudget> computeStorageBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _readEntries(prefs).values;

    var imagesBytes = 0;
    var thumbsBytes = 0;
    var docsBytes = 0;
    for (final entry in entries) {
      switch (entry.kind) {
        case MediaBudgetKind.image:
          imagesBytes += entry.sizeBytes;
          break;
        case MediaBudgetKind.thumb:
          thumbsBytes += entry.sizeBytes;
          break;
        case MediaBudgetKind.document:
          docsBytes += entry.sizeBytes;
          break;
      }
    }

    return StorageBudget(
      totalBytesUsedKnown: imagesBytes + thumbsBytes + docsBytes,
      imagesBytes: imagesBytes,
      thumbsBytes: thumbsBytes,
      docsBytes: docsBytes,
    );
  }

  String humanReadableBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, MediaBudgetEntry> _readEntries(SharedPreferences prefs) {
    final raw = prefs.getString(_entriesKey);
    if (raw == null || raw.trim().isEmpty) return <String, MediaBudgetEntry>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String, MediaBudgetEntry>{};
      final map = <String, MediaBudgetEntry>{};
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        final entry = MediaBudgetEntry.fromJson(item);
        if (entry == null) continue;
        map[entry.dedupeKey] = entry;
      }
      return map;
    } catch (_) {
      return <String, MediaBudgetEntry>{};
    }
  }

  String _encodeEntries(Iterable<MediaBudgetEntry> entries) {
    final data = entries.map((entry) => entry.toJson()).toList();
    return jsonEncode(data);
  }
}

final storageBudgetServiceProvider = Provider<StorageBudgetService>(
  (ref) => StorageBudgetService(),
);

final storageBudgetProvider = FutureProvider<StorageBudget>((ref) async {
  return ref.watch(storageBudgetServiceProvider).computeStorageBudget();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lowDataModeKey = 'low_data_mode_enabled';
const _lastReadChapterIdKey = 'last_read_chapter_id';
const _lastReadChapterTitleKey = 'last_read_chapter_title';
const _lastReadChapterUpdatedAtKey = 'last_read_chapter_updated_at';

final lowDataModeProvider = AsyncNotifierProvider<LowDataModeNotifier, bool>(
  LowDataModeNotifier.new,
);

final lowDataModeEnabledProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(lowDataModeProvider);
  return asyncValue.valueOrNull ?? true;
});

final lastReadChapterProvider =
    AsyncNotifierProvider<LastReadChapterNotifier, LastReadChapter?>(
      LastReadChapterNotifier.new,
    );

class LowDataModeNotifier extends AsyncNotifier<bool> {
  SharedPreferences? _prefs;

  @override
  Future<bool> build() async {
    final prefs = await _ensurePrefs();
    return prefs.getBool(_lowDataModeKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    final prefs = await _ensurePrefs();
    await prefs.setBool(_lowDataModeKey, enabled);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }
}

class LastReadChapter {
  final String chapterId;
  final String? chapterTitle;
  final DateTime updatedAt;

  const LastReadChapter({
    required this.chapterId,
    this.chapterTitle,
    required this.updatedAt,
  });
}

class LastReadChapterNotifier extends AsyncNotifier<LastReadChapter?> {
  SharedPreferences? _prefs;

  @override
  Future<LastReadChapter?> build() async {
    final prefs = await _ensurePrefs();
    return _readValue(prefs);
  }

  Future<void> setLastReadChapter({
    required String chapterId,
    String? chapterTitle,
  }) async {
    final prefs = await _ensurePrefs();
    final now = DateTime.now();
    await prefs.setString(_lastReadChapterIdKey, chapterId);
    if (chapterTitle != null && chapterTitle.trim().isNotEmpty) {
      await prefs.setString(_lastReadChapterTitleKey, chapterTitle.trim());
    }
    await prefs.setString(_lastReadChapterUpdatedAtKey, now.toIso8601String());
    state = AsyncData(
      LastReadChapter(
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        updatedAt: now,
      ),
    );
  }

  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_lastReadChapterIdKey);
    await prefs.remove(_lastReadChapterTitleKey);
    await prefs.remove(_lastReadChapterUpdatedAtKey);
    state = const AsyncData(null);
  }

  LastReadChapter? _readValue(SharedPreferences prefs) {
    final id = prefs.getString(_lastReadChapterIdKey);
    if (id == null || id.trim().isEmpty) return null;
    final title = prefs.getString(_lastReadChapterTitleKey);
    final updatedRaw = prefs.getString(_lastReadChapterUpdatedAtKey);
    final updatedAt = updatedRaw == null ? null : DateTime.tryParse(updatedRaw);

    return LastReadChapter(
      chapterId: id.trim(),
      chapterTitle: title?.trim().isEmpty == true ? null : title?.trim(),
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }
}

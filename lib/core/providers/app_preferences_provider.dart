import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/core/localization/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lowDataModeKey = 'low_data_mode_enabled';
const _textScaleFactorKey = 'text_scale_factor';
const _appLanguageKey = 'app_language_code';
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

final textScaleProvider = AsyncNotifierProvider<TextScaleNotifier, double>(
  TextScaleNotifier.new,
);

final textScaleFactorProvider = Provider<double>((ref) {
  final asyncValue = ref.watch(textScaleProvider);
  return asyncValue.valueOrNull ?? 1.0;
});

final appLanguageProvider =
    AsyncNotifierProvider<AppLanguageNotifier, AppLanguage>(
      AppLanguageNotifier.new,
    );

final currentAppLanguageProvider = Provider<AppLanguage>((ref) {
  final asyncValue = ref.watch(appLanguageProvider);
  return asyncValue.valueOrNull ?? AppLanguage.english;
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

class TextScaleNotifier extends AsyncNotifier<double> {
  SharedPreferences? _prefs;

  @override
  Future<double> build() async {
    final prefs = await _ensurePrefs();
    final stored = prefs.getDouble(_textScaleFactorKey) ?? 1.0;
    return _normalize(stored);
  }

  Future<void> setScale(double scale) async {
    final normalized = _normalize(scale);
    state = AsyncData(normalized);
    final prefs = await _ensurePrefs();
    await prefs.setDouble(_textScaleFactorKey, normalized);
  }

  Future<void> reset() async {
    state = const AsyncData(1.0);
    final prefs = await _ensurePrefs();
    await prefs.setDouble(_textScaleFactorKey, 1.0);
  }

  double _normalize(double value) {
    return value.clamp(0.85, 1.35).toDouble();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }
}

class AppLanguageNotifier extends AsyncNotifier<AppLanguage> {
  SharedPreferences? _prefs;

  @override
  Future<AppLanguage> build() async {
    final prefs = await _ensurePrefs();
    final stored = prefs.getString(_appLanguageKey);
    return AppLanguage.fromStorageCode(stored);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = AsyncData(language);
    final prefs = await _ensurePrefs();
    await prefs.setString(_appLanguageKey, language.storageCode);
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

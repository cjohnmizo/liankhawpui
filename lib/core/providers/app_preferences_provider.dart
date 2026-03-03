import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lowDataModeKey = 'low_data_mode_enabled';

final lowDataModeProvider = AsyncNotifierProvider<LowDataModeNotifier, bool>(
  LowDataModeNotifier.new,
);

final lowDataModeEnabledProvider = Provider<bool>((ref) {
  final asyncValue = ref.watch(lowDataModeProvider);
  return asyncValue.valueOrNull ?? true;
});

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

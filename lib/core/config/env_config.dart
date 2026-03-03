import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => _getRequired('SUPABASE_URL');

  // Supports both Supabase naming conventions.
  static String get supabaseAnonKey =>
      _getOptional('SUPABASE_ANON_KEY').isNotEmpty
      ? _getOptional('SUPABASE_ANON_KEY')
      : _getRequired('SUPABASE_PUBLISHABLE_KEY');

  static String get powerSyncUrl => _getRequired('POWERSYNC_URL');

  static String get oneSignalAppId => _getOptional('ONESIGNAL_APP_ID');

  static String get powerSyncTokenFunction {
    final value = _getOptional('POWERSYNC_TOKEN_FUNCTION');
    return value.isNotEmpty ? value : 'powersync-token';
  }

  static void validateRequired() {
    final missing = <String>[];

    if (_getOptional('SUPABASE_URL').isEmpty) {
      missing.add('SUPABASE_URL');
    }

    if (_getOptional('SUPABASE_ANON_KEY').isEmpty &&
        _getOptional('SUPABASE_PUBLISHABLE_KEY').isEmpty) {
      missing.add('SUPABASE_ANON_KEY (or SUPABASE_PUBLISHABLE_KEY)');
    }

    if (_getOptional('POWERSYNC_URL').isEmpty) {
      missing.add('POWERSYNC_URL');
    }

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required environment values: ${missing.join(', ')}',
      );
    }
  }

  static String _getRequired(String key) {
    final value = _getOptional(key);
    if (value.isEmpty) {
      throw StateError('Missing environment value: $key');
    }
    return value;
  }

  static String _getOptional(String key) {
    return (dotenv.env[key] ?? '').trim();
  }
}

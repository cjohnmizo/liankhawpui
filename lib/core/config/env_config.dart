import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get powerSyncUrl => dotenv.env['POWERSYNC_URL'] ?? '';
  static String get oneSignalAppId => dotenv.env['ONESIGNAL_APP_ID'] ?? '';
}

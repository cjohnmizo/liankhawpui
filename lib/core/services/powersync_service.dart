import 'package:powersync/powersync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:liankhawpui/data/local/db_schema.dart';
import 'package:liankhawpui/data/sync/supabase_connector.dart';

class PowerSyncService {
  static final PowerSyncService _instance = PowerSyncService._internal();
  factory PowerSyncService() => _instance;
  PowerSyncService._internal();

  late final PowerSyncDatabase db;
  bool _isInitialized = false;
  bool _isConnected = false;

  Future<void> initialize({bool enableRemoteSync = true}) async {
    if (!_isInitialized) {
      final dir = await getApplicationSupportDirectory();
      final path = join(dir.path, 'liankhawpui.db');

      // Open the database
      db = PowerSyncDatabase(schema: schema, path: path);
      await db.initialize();

      _isInitialized = true;
    }

    if (enableRemoteSync && !_isConnected) {
      // Create and connect the connector only when remote sync is enabled.
      final connector = SupabaseConnector(db);
      db.connect(connector: connector);
      _isConnected = true;
    }
  }
}

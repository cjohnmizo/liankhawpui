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

  Future<void> initialize() async {
    if (_isInitialized) return;

    final dir = await getApplicationSupportDirectory();
    final path = join(dir.path, 'liankhawpui.db');

    // Open the database
    db = PowerSyncDatabase(schema: schema, path: path);
    await db.initialize();

    // Create and connect the connector
    final connector = SupabaseConnector(db);
    db.connect(connector: connector);

    _isInitialized = true;
  }
}

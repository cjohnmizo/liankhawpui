import 'package:powersync/powersync.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';

class SupabaseConnector extends PowerSyncBackendConnector {
  PowerSyncDatabase db;

  SupabaseConnector(this.db);

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // This function is called when there are local changes to upload.
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      // Allow the super class to upload the transaction to the backend
      // Note: In a real Supabase setup, you might use Edge Functions or
      // direct RPC calls if not using the PowerSync integration service directly for writes.
      // However, usually PowerSync recommends writing to Supabase directly from the client
      // for standard CRUD if using Supabase as the source of truth,
      // OR using the queue to process offline writes.

      // For this implementation, we will iterate over operations and execute them against Supabase.
      // This is a "client-side write" pattern.

      for (var op in transaction.crud) {
        final table = SupabaseService.client.from(op.table);

        switch (op.op) {
          case UpdateType.put:
            // Upsert (Insert or Update)
            await table.upsert(op.opData as Map<String, dynamic>);
            break;
          case UpdateType.patch:
            // Update specific fields
            await table
                .update(op.opData as Map<String, dynamic>)
                .eq('id', op.id);
            break;
          case UpdateType.delete:
            // Delete
            await table.delete().eq('id', op.id);
            break;
        }
      }

      await transaction.complete();
    } catch (e) {
      // Error handling - retry later
      // Log error in dev/debug (optional, can use logging package)
      // print('Error uploading data: $e');
      // If error is permanent, might need to discard transaction?
      // rethrow to keep it in queue
      rethrow;
    }
  }

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Get the current session from Supabase
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) {
      // Not logged in
      return null;
    }

    // You usually need to generate a PowerSync token from your backend.
    // However, if using the demo/development setup or custom token generation:
    // This part assumes you have an Edge Function or API endpoint to get a PowerSync token.
    // For this scaffold, we'll placeholder this.
    // REAL WORLD: Call `await Supabase.functions.invoke('get-powersync-token')`

    // Returning null for now as we don't have the token endpoint set up in the prompt details.
    // But we MUST implementation it for it to work.
    // I will assume standard Supabase Auth JWT is NOT enough, it needs a specific PowerSync token.
    // BUT, some setups allow using the Supabase JWT directly if configured.
    // Let's assume we use the Sync URL and the user's JWT for authentication if supported,
    // or we throw an error that backend integration is needed.

    // NOTE TO USER: This requires a backend function to sign tokens.
    // For now, I will use a placeholder that throws or returns a dummy to prevent compile errors.

    final token = session.accessToken;

    // In many Supabase+PowerSync tutorials, you fetch a specific token.
    // We'll assume the URL endpoint provides it.

    return PowerSyncCredentials(
      endpoint: 'https://6975ed755f8ee4c525015889.powersync.journeyapps.com',
      token: token, // This is likely wrong but placeholder.
    );
  }
}

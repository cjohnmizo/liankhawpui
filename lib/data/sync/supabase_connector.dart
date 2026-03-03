import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:liankhawpui/core/config/env_config.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';

class SupabaseConnector extends PowerSyncBackendConnector {
  final PowerSyncDatabase db;

  SupabaseConnector(this.db);

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      for (final op in transaction.crud) {
        final table = SupabaseService.client.from(op.table);
        final payload = op.opData is Map
            ? Map<String, dynamic>.from(op.opData as Map)
            : <String, dynamic>{};

        switch (op.op) {
          case UpdateType.put:
            await table.upsert(payload);
            break;
          case UpdateType.patch:
            await table.update(payload).eq('id', op.id);
            break;
          case UpdateType.delete:
            await table.delete().eq('id', op.id);
            break;
        }
      }

      await transaction.complete();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) return null;

    final token = await _fetchPowerSyncToken() ?? session.accessToken;

    return PowerSyncCredentials(endpoint: EnvConfig.powerSyncUrl, token: token);
  }

  Future<String?> _fetchPowerSyncToken() async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        EnvConfig.powerSyncTokenFunction,
      );
      return _extractToken(response.data);
    } catch (error) {
      debugPrint(
        'PowerSync token function unavailable, using Supabase access token fallback: $error',
      );
      return null;
    }
  }

  String? _extractToken(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return (map['token'] as String?)?.trim();
    }

    if (data is String) {
      final value = data.trim();
      if (value.isEmpty) return null;

      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return (Map<String, dynamic>.from(decoded)['token'] as String?)
              ?.trim();
        }
      } catch (_) {
        // The function may return a raw token string instead of JSON.
      }

      return value;
    }

    return null;
  }
}

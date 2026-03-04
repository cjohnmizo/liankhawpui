import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:powersync/powersync.dart';
import 'package:liankhawpui/core/config/env_config.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

class SupabaseConnector extends PowerSyncBackendConnector {
  final PowerSyncDatabase db;
  final Set<String> _sentAnnouncementPushIds = <String>{};

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
            await _sendAnnouncementPushIfNeeded(
              tableName: op.table,
              operation: op.op,
              payload: payload,
              fallbackId: op.id.toString(),
            );
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

  Future<void> _sendAnnouncementPushIfNeeded({
    required String tableName,
    required UpdateType operation,
    required Map<String, dynamic> payload,
    String? fallbackId,
  }) async {
    if (tableName != 'announcements' || operation != UpdateType.put) return;

    final createdAt = _readNonEmptyString(payload['created_at']);
    final updatedAt = _readNonEmptyString(payload['updated_at']);

    // Treat only first-write rows as publish events. Edits should not push.
    if (createdAt == null || updatedAt == null || createdAt != updatedAt) {
      return;
    }

    final announcementId = _readNonEmptyString(payload['id']) ?? fallbackId;
    final title = _readNonEmptyString(payload['title']);
    final content = _readNonEmptyString(payload['content']);

    if (announcementId == null || title == null || content == null) return;
    if (_sentAnnouncementPushIds.contains(announcementId)) return;

    final session = await _getFreshSession();
    if (session == null) return;

    try {
      final endpoint = Uri.parse(
        '${EnvConfig.supabaseUrl}/functions/v1/send-notification',
      );

      final response = await http.post(
        endpoint,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': EnvConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': 'New Announcement',
          'message': _buildAnnouncementMessage(title: title, content: content),
          'included_segments': ['Active Subscriptions'],
          'idempotency_key': announcementId,
          'data': {'type': 'announcement', 'announcement_id': announcementId},
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _sentAnnouncementPushIds.add(announcementId);
        return;
      }

      debugPrint(
        'Announcement push send failed (${response.statusCode}): ${response.body}',
      );
    } catch (error) {
      debugPrint('Announcement push send failed: $error');
    }
  }

  String _buildAnnouncementMessage({
    required String title,
    required String content,
  }) {
    final normalizedTitle = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedContent = content.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalizedContent.isEmpty) return normalizedTitle;

    const maxLength = 140;
    final snippet = normalizedContent.length > maxLength
        ? '${normalizedContent.substring(0, maxLength)}...'
        : normalizedContent;

    return '$normalizedTitle\n$snippet';
  }

  String? _readNonEmptyString(Object? value) {
    final parsed = value?.toString().trim();
    if (parsed == null || parsed.isEmpty) return null;
    return parsed;
  }

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = await _getFreshSession();
    if (session == null) return null;

    final token =
        await _fetchPowerSyncToken(session.accessToken) ?? session.accessToken;

    return PowerSyncCredentials(endpoint: EnvConfig.powerSyncUrl, token: token);
  }

  Future<Session?> _getFreshSession() async {
    final auth = SupabaseService.client.auth;
    try {
      await auth.refreshSession();
    } catch (_) {
      // Fall back to the active session snapshot.
    }
    return auth.currentSession;
  }

  Future<String?> _fetchPowerSyncToken(String accessToken) async {
    final bearer = accessToken.startsWith('Bearer ')
        ? accessToken
        : 'Bearer $accessToken';

    try {
      final endpoint = Uri.parse(
        '${EnvConfig.supabaseUrl}/functions/v1/${EnvConfig.powerSyncTokenFunction}',
      );
      final response = await http.post(
        endpoint,
        headers: {
          'Authorization': bearer,
          'apikey': EnvConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: '{}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = _extractToken(response.body);
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } else {
        debugPrint(
          'PowerSync token function HTTP call failed (${response.statusCode}), falling back to Supabase access token.',
        );
      }
    } catch (error) {
      debugPrint(
        'PowerSync token function HTTP call unavailable, falling back to Supabase access token: $error',
      );
    }

    return null;
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

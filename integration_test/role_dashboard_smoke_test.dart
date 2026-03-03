import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liankhawpui/core/config/env_config.dart';
import 'package:liankhawpui/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

const String _editorEmail = String.fromEnvironment('TEST_EDITOR_EMAIL');
const String _editorPassword = String.fromEnvironment('TEST_EDITOR_PASSWORD');
const String _adminEmail = String.fromEnvironment('TEST_ADMIN_EMAIL');
const String _adminPassword = String.fromEnvironment('TEST_ADMIN_PASSWORD');
const bool _runAdminUserFlow = bool.fromEnvironment(
  'TEST_ADMIN_USERS_FLOW',
  defaultValue: false,
);

final bool _hasEditorCreds =
    _editorEmail.isNotEmpty && _editorPassword.isNotEmpty;
final bool _hasAdminCreds = _adminEmail.isNotEmpty && _adminPassword.isNotEmpty;

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for finder: $finder');
}

Future<void> waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 25),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(step);
    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) return;
    }
  }
  fail('Timed out waiting for any expected screen state.');
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final finder = find.text(text);
  await waitFor(tester, finder, timeout: timeout);
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> openDrawerFromBottomMenu(WidgetTester tester) async {
  await tapText(tester, 'Menu');
  await waitFor(tester, find.text('Settings'));
}

Future<void> tapBackButton(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 12),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    final didPop = await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 700));
    if (didPop) return;

    final rounded = find.byIcon(Icons.arrow_back_rounded);
    if (rounded.evaluate().isNotEmpty) {
      await tester.ensureVisible(rounded.first);
      await tester.tap(rounded.first);
      await tester.pump(const Duration(milliseconds: 700));
      return;
    }

    final ios = find.byIcon(Icons.arrow_back_ios_new_rounded);
    if (ios.evaluate().isNotEmpty) {
      await tester.ensureVisible(ios.first);
      await tester.tap(ios.first);
      await tester.pump(const Duration(milliseconds: 700));
      return;
    }

    await tester.pump(step);
  }

  fail('Timed out waiting for a back action');
}

Future<void> signInViaApi(
  WidgetTester tester, {
  required List<(String email, String password)> candidates,
}) async {
  final client = Supabase.instance.client;
  await client.auth.signOut();

  AuthResponse? response;
  Object? lastError;
  for (final candidate in candidates) {
    try {
      response = await client.auth.signInWithPassword(
        email: candidate.$1,
        password: candidate.$2,
      );
      if (response.session != null) {
        lastError = null;
        break;
      }
    } catch (e) {
      lastError = e;
    }
  }

  if (response == null || response.session == null) {
    final tried = candidates.map((c) => c.$1).join(', ');
    fail(
      'API sign-in failed: no session returned. Tried: $tried. Last error: $lastError',
    );
  }

  // Give GoRouter + auth stream time to redirect to home.
  await waitForAny(tester, [
    find.text('Menu'),
    find.text('Welcome Back'),
  ], timeout: const Duration(seconds: 45));

  final endTime = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (find.text('Menu').evaluate().isNotEmpty) {
      return;
    }
  }

  fail('Timed out waiting for Menu after API sign-in');
}

Future<void> openAdminDashboard(WidgetTester tester) async {
  await waitFor(
    tester,
    find.text('Menu'),
    timeout: const Duration(seconds: 30),
  );
  await openDrawerFromBottomMenu(tester);
  await waitFor(
    tester,
    find.text('Admin Dashboard'),
    timeout: const Duration(seconds: 20),
  );
  await tapText(tester, 'Admin Dashboard');
  await waitFor(
    tester,
    find.text('Overview'),
    timeout: const Duration(seconds: 25),
  );
}

Future<void> returnToHome(WidgetTester tester) async {
  final menu = find.text('Menu');
  if (menu.evaluate().isNotEmpty) return;

  await tapBackButton(tester);
  if (menu.evaluate().isNotEmpty) return;

  await tapBackButton(tester);
  await waitFor(tester, menu, timeout: const Duration(seconds: 20));
}

Future<void> signOutFromHome(WidgetTester tester) async {
  if (find.text('Menu').evaluate().isNotEmpty) {
    await openDrawerFromBottomMenu(tester);
    if (find.text('Sign Out').evaluate().isNotEmpty) {
      await tapText(tester, 'Sign Out');
    }
  }

  await Supabase.instance.client.auth.signOut();
  final signOutEnd = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(signOutEnd)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (Supabase.instance.client.auth.currentSession == null) {
      break;
    }
  }

  await waitForAny(tester, [
    find.text('Welcome Back'),
    find.text('Menu'),
  ], timeout: const Duration(seconds: 20));

  if (find.text('Menu').evaluate().isNotEmpty) {
    await openDrawerFromBottomMenu(tester);
    await waitFor(
      tester,
      find.text('Sign In'),
      timeout: const Duration(seconds: 15),
    );
  }
}

Map<String, dynamic> asJsonMap(dynamic value, {required String operation}) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  fail('$operation failed: response payload is not a JSON object.');
}

void ensureFunctionOk(
  dynamic data, {
  required String operation,
  required String expectedStatus,
}) {
  final payload = asJsonMap(data, operation: operation);

  final error = payload['error'];
  if (error is String && error.trim().isNotEmpty) {
    fail('$operation failed: $error');
  }

  final status = payload['status'] as String?;
  if (status != expectedStatus) {
    fail(
      '$operation failed: expected status "$expectedStatus", got "$status".',
    );
  }
}

Future<String> requireAccessToken({required String operation}) async {
  final client = Supabase.instance.client;
  try {
    await client.auth.refreshSession();
  } catch (_) {
    // If refresh is unavailable, fall back to the current session token.
  }

  final token = client.auth.currentSession?.accessToken;
  if (token == null || token.isEmpty) {
    fail('$operation failed: no authenticated session token available.');
  }
  return token;
}

Future<Map<String, dynamic>> invokeAdminUsers(
  Map<String, dynamic> body, {
  required String operation,
}) async {
  final accessToken = await requireAccessToken(operation: operation);
  final endpoint = Uri.parse(
    '${EnvConfig.supabaseUrl}/functions/v1/admin-users',
  );

  final httpClient = HttpClient();
  final request = await httpClient.postUrl(endpoint);
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
  request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
  request.write(jsonEncode(body));

  final response = await request.close();
  final responseText = await response.transform(utf8.decoder).join();
  httpClient.close();

  dynamic decoded;
  final rawBody = responseText.trim();
  if (rawBody.isEmpty) {
    decoded = <String, dynamic>{};
  } else {
    try {
      decoded = jsonDecode(rawBody);
    } catch (_) {
      fail('$operation failed: non-JSON response body: $responseText');
    }
  }

  final payload = asJsonMap(decoded, operation: operation);
  if (response.statusCode >= 400) {
    final message =
        payload['error'] ?? payload['message'] ?? 'HTTP ${response.statusCode}';
    fail('$operation failed (${response.statusCode}): $message');
  }

  return payload;
}

Future<Map<String, dynamic>> waitForProfileRole({
  required String userId,
  required String expectedRole,
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 500),
}) async {
  final client = Supabase.instance.client;
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    final row = await client
        .from('profiles')
        .select('id, email, role')
        .eq('id', userId)
        .maybeSingle();

    if (row != null) {
      final profile = asJsonMap(row, operation: 'profile role lookup');
      final role = (profile['role'] as String?)?.toLowerCase();
      if (role == expectedRole.toLowerCase()) {
        return profile;
      }
    }

    await Future<void>.delayed(step);
  }

  fail(
    'Timed out waiting for profile role "$expectedRole" for user "$userId".',
  );
}

Future<void> waitForProfileDeleted({
  required String userId,
  Duration timeout = const Duration(seconds: 30),
  Duration step = const Duration(milliseconds: 500),
}) async {
  final client = Supabase.instance.client;
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    final row = await client
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      return;
    }

    await Future<void>.delayed(step);
  }

  fail('Timed out waiting for profile deletion for user "$userId".');
}

Future<void> adminCreateAndPromoteUserFlow() async {
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'liankhawpui.it.$stamp@example.com';
  final fullName = 'IT User $stamp';
  const password = 'TempPass123';
  final client = Supabase.instance.client;

  String? createdUserId;
  Object? testError;
  try {
    final activeUserId = client.auth.currentUser?.id;
    if (activeUserId == null || activeUserId.isEmpty) {
      fail('Admin flow failed: no signed-in user is available.');
    }

    await waitForProfileRole(userId: activeUserId, expectedRole: 'admin');

    final createPayload = await invokeAdminUsers({
      'action': 'create_user',
      'email': email,
      'password': password,
      'full_name': fullName,
      'role': 'user',
    }, operation: 'create_user');
    ensureFunctionOk(
      createPayload,
      operation: 'create_user',
      expectedStatus: 'created',
    );
    final userPayload = asJsonMap(
      createPayload['user'],
      operation: 'create_user user payload',
    );

    createdUserId = userPayload['id'] as String?;
    if (createdUserId == null || createdUserId.isEmpty) {
      fail('create_user failed: response is missing user.id');
    }

    final createdProfile = await waitForProfileRole(
      userId: createdUserId,
      expectedRole: 'user',
    );
    expect((createdProfile['email'] as String?)?.toLowerCase(), email);

    final updatePayload = await invokeAdminUsers({
      'action': 'update_role',
      'user_id': createdUserId,
      'role': 'editor',
    }, operation: 'update_role');
    ensureFunctionOk(
      updatePayload,
      operation: 'update_role',
      expectedStatus: 'updated',
    );

    await waitForProfileRole(userId: createdUserId, expectedRole: 'editor');
  } catch (error) {
    testError = error;
    rethrow;
  } finally {
    if (createdUserId != null && createdUserId.isNotEmpty) {
      try {
        final deletePayload = await invokeAdminUsers({
          'action': 'delete_user',
          'user_id': createdUserId,
          'hard_delete': true,
        }, operation: 'delete_user');
        ensureFunctionOk(
          deletePayload,
          operation: 'delete_user',
          expectedStatus: 'deleted',
        );
        await waitForProfileDeleted(userId: createdUserId);
      } catch (cleanupError) {
        if (testError == null) {
          fail('Cleanup failed for "$createdUserId": $cleanupError');
        } else {
          debugPrint(
            'Cleanup warning for "$createdUserId" after test failure: $cleanupError',
          );
        }
      }
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Editor dashboard smoke test', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));

    await waitForAny(tester, [
      find.text('Menu'),
      find.text('Welcome Back'),
    ], timeout: const Duration(seconds: 45));

    await signInViaApi(
      tester,
      candidates: [
        (_editorEmail, _editorPassword),
        if (_hasAdminCreds) (_adminEmail, _adminPassword), // fallback
      ],
    );

    await openAdminDashboard(tester);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('News Articles'), findsOneWidget);

    await tapText(tester, 'News Articles');
    await waitFor(
      tester,
      find.text('Manage News'),
      timeout: const Duration(seconds: 25),
    );
    expect(find.text('New Article'), findsOneWidget);

    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));
  }, skip: !_hasEditorCreds);

  testWidgets('Admin dashboard smoke test', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));

    await waitForAny(tester, [
      find.text('Menu'),
      find.text('Welcome Back'),
    ], timeout: const Duration(seconds: 45));

    await signInViaApi(tester, candidates: [(_adminEmail, _adminPassword)]);

    await openAdminDashboard(tester);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);

    await tapText(tester, 'Users');
    await waitFor(
      tester,
      find.text('Manage Users'),
      timeout: const Duration(seconds: 25),
    );
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));
  }, skip: !_hasAdminCreds);

  testWidgets('Admin user management flow', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));

    await waitForAny(tester, [
      find.text('Menu'),
      find.text('Welcome Back'),
    ], timeout: const Duration(seconds: 45));

    await signInViaApi(tester, candidates: [(_adminEmail, _adminPassword)]);
    await openAdminDashboard(tester);

    await tapText(tester, 'Users');
    await waitFor(
      tester,
      find.text('Manage Users'),
      timeout: const Duration(seconds: 25),
    );

    await adminCreateAndPromoteUserFlow();

    await Supabase.instance.client.auth.signOut();
    await tester.pump(const Duration(seconds: 1));
  }, skip: !_hasAdminCreds || !_runAdminUserFlow);
}

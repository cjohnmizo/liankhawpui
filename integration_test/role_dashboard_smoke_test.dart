import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liankhawpui/main.dart' as app;

const String _editorEmail = String.fromEnvironment('TEST_EDITOR_EMAIL');
const String _editorPassword = String.fromEnvironment('TEST_EDITOR_PASSWORD');
const String _adminEmail = String.fromEnvironment('TEST_ADMIN_EMAIL');
const String _adminPassword = String.fromEnvironment('TEST_ADMIN_PASSWORD');

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

Future<void> ensureLoginScreen(WidgetTester tester) async {
  final welcomeBack = find.text('Welcome Back');
  final menu = find.text('Menu');

  if (welcomeBack.evaluate().isNotEmpty) return;

  if (menu.evaluate().isEmpty) {
    await waitForAny(tester, [
      menu,
      welcomeBack,
    ], timeout: const Duration(seconds: 45));
    if (welcomeBack.evaluate().isNotEmpty) return;
  }

  await openDrawerFromBottomMenu(tester);
  if (find.text('Sign Out').evaluate().isNotEmpty) {
    await tapText(tester, 'Sign Out');
  } else {
    await tapText(tester, 'Sign In');
  }

  await waitFor(tester, welcomeBack, timeout: const Duration(seconds: 30));
}

Future<void> signInWithCredentials(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await waitFor(
    tester,
    find.text('Welcome Back'),
    timeout: const Duration(seconds: 30),
  );

  final formFields = find.byType(TextFormField);
  await waitFor(tester, formFields);
  expect(formFields, findsNWidgets(2));
  final emailField = formFields.at(0);
  final passwordField = formFields.at(1);

  await tester.tap(emailField);
  await tester.pump(const Duration(milliseconds: 150));
  await waitFor(tester, emailField);
  await tester.enterText(emailField, email);
  await tester.pump(const Duration(milliseconds: 250));
  final emailText = tester.widget<TextFormField>(emailField).controller?.text;
  expect(emailText, equals(email));

  await tester.tap(passwordField);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.enterText(passwordField, password);
  await tester.pump(const Duration(milliseconds: 250));

  // Trigger form submit from password field first, then fallback to button tap.
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump(const Duration(milliseconds: 800));
  if (find.text('Menu').evaluate().isEmpty) {
    await tapText(tester, 'Sign In');
  }

  final endTime = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 300));

    if (find.text('Menu').evaluate().isNotEmpty) return;

    final loginErrorTexts = <String>[
      'Invalid email or password.',
      'Please confirm your email address.',
      'Internet connection is required to login.',
    ];

    for (final text in loginErrorTexts) {
      if (find.text(text).evaluate().isNotEmpty) {
        fail('Login failed: $text');
      }
    }

    if (find
        .textContaining('An unexpected error occurred')
        .evaluate()
        .isNotEmpty) {
      fail('Login failed: unexpected error snackbar shown');
    }
  }

  fail('Timed out waiting for Menu after sign in');
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
  await waitFor(
    tester,
    find.text('Menu'),
    timeout: const Duration(seconds: 25),
  );
  await openDrawerFromBottomMenu(tester);
  await waitFor(
    tester,
    find.text('Sign Out'),
    timeout: const Duration(seconds: 15),
  );
  await tapText(tester, 'Sign Out');
  await waitFor(
    tester,
    find.text('Welcome Back'),
    timeout: const Duration(seconds: 30),
  );
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

    await ensureLoginScreen(tester);
    await signInWithCredentials(
      tester,
      email: _editorEmail,
      password: _editorPassword,
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

    await returnToHome(tester);
    await signOutFromHome(tester);
  }, skip: !_hasEditorCreds);

  testWidgets('Admin dashboard smoke test', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));

    await waitForAny(tester, [
      find.text('Menu'),
      find.text('Welcome Back'),
    ], timeout: const Duration(seconds: 45));

    await ensureLoginScreen(tester);
    await signInWithCredentials(
      tester,
      email: _adminEmail,
      password: _adminPassword,
    );

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

    await returnToHome(tester);
    await signOutFromHome(tester);
  }, skip: !_hasAdminCreds);
}

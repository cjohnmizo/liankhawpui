import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liankhawpui/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

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

    final generic = find.byIcon(Icons.arrow_back);
    if (generic.evaluate().isNotEmpty) {
      await tester.ensureVisible(generic.first);
      await tester.tap(generic.first);
      await tester.pump(const Duration(milliseconds: 700));
      return;
    }

    await tester.pump(step);
  }

  fail('Timed out waiting for a visible in-app back button');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Guest flow functional smoke test', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await Supabase.instance.client.auth.signOut().catchError((_) => {});
    await tester.pumpAndSettle();

    // Home (Guest) - wait until bottom navigation is ready.
    await waitFor(
      tester,
      find.text('Menu'),
      timeout: const Duration(seconds: 40),
    );
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Bottom navigation: News
    await tapText(tester, 'News');
    await waitFor(tester, find.text('News Feed'));

    // Bottom navigation: Updates (Announcements)
    await tapText(tester, 'Updates');
    await waitFor(tester, find.text('Announcements'));

    // Drawer: Organizations
    await openDrawerFromBottomMenu(tester);
    await tapText(tester, 'Organizations');
    await waitFor(tester, find.text('Organizations'));
    await tapBackButton(tester);

    // Drawer: Directory
    await openDrawerFromBottomMenu(tester);
    await tapText(tester, 'Directory');
    await waitFor(tester, find.text('Khawlian Chanchin'));
    await tapBackButton(tester);

    // Drawer: Settings and theme toggle control presence
    await openDrawerFromBottomMenu(tester);
    await tapText(tester, 'Settings');
    await waitFor(tester, find.text('Settings'));
    expect(find.text('Dark Mode'), findsOneWidget);
    final darkModeSwitch = find.byType(Switch).first;
    await tester.tap(darkModeSwitch);
    await tester.pump(const Duration(milliseconds: 800));
    await tapBackButton(tester);

    // Drawer -> Sign In
    await openDrawerFromBottomMenu(tester);
    await tapText(tester, 'Sign In');
    await waitFor(tester, find.text('Welcome Back'));
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    // Forgot password screen
    await tapText(tester, 'Forgot Password?');
    await waitFor(tester, find.text('Forgot Password?'));
    await tapBackButton(tester);

    // Registration screen
    await tapText(tester, 'Sign Up');
    await waitFor(tester, find.text('Create Account'));
    await tapBackButton(tester);

    // Back to home from login
    await tapBackButton(tester);
    await tapText(tester, 'Home');
    await waitFor(tester, find.text('Featured News'));

    // Guest profile access should route to login screen
    final profileIcon = find.byIcon(Icons.person_rounded);
    await waitFor(tester, profileIcon);
    await tester.tap(profileIcon.first);
    await tester.pump(const Duration(seconds: 1));
    await waitFor(tester, find.text('Welcome Back'));
  });
}

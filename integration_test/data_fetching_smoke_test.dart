import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/features/announcement/data/announcement_repository.dart';
import 'package:liankhawpui/features/story/data/story_repository.dart';
import 'package:liankhawpui/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

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
  fail('Timed out waiting for expected screen state.');
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final finder = find.text(text);
  await waitFor(tester, finder, timeout: timeout);
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> scrollUntilTextVisible(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 25),
  double dy = 360,
}) async {
  final endTime = DateTime.now().add(timeout);
  final finder = find.text(text);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pump(const Duration(milliseconds: 350));
      return;
    }

    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) {
      continue;
    }
    await tester.drag(scrollable.first, Offset(0, -dy));
    await tester.pump(const Duration(milliseconds: 450));
  }

  fail('Timed out scrolling to text: "$text"');
}

Future<void> openDrawerFromBottomMenu(WidgetTester tester) async {
  await tapText(tester, 'Menu');
  await waitFor(tester, find.text('Settings'));
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

  await waitForAny(tester, [
    find.text('Menu'),
    find.text('Welcome Back'),
  ], timeout: const Duration(seconds: 45));

  await waitFor(
    tester,
    find.text('Menu'),
    timeout: const Duration(seconds: 30),
  );
}

Future<void> signOutBestEffort(WidgetTester tester) async {
  await Supabase.instance.client.auth.signOut();
  final endTime = DateTime.now().add(const Duration(seconds: 8));
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.text('Menu').evaluate().isNotEmpty ||
        find.text('Welcome Back').evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> deleteAnnouncementsByTitle(String title) async {
  final db = PowerSyncService().db;
  try {
    await db.execute('DELETE FROM announcements WHERE title = ?', [title]);
  } catch (_) {
    // best effort cleanup
  }
}

Future<
  ({
    String bookId,
    String chapterId,
    String bookTitle,
    String chapterTitle,
    String chapterContent,
  })
>
seedBookSample() async {
  final repo = StoryRepository();
  final book = await repo.getOrCreateSingleBook();
  final db = PowerSyncService().db;
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final chapterId = 'it-chapter-$stamp';
  final chapterTitle = 'IT Chapter $stamp';
  final chapterContent = 'Sample chapter content $stamp';

  await db.execute(
    '''
    INSERT INTO chapters (id, book_id, title, content, image_url, chapter_number, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      chapterId,
      book.id,
      chapterTitle,
      chapterContent,
      null,
      1,
      DateTime.now().toIso8601String(),
    ],
  );

  return (
    bookId: book.id,
    chapterId: chapterId,
    bookTitle: book.title,
    chapterTitle: chapterTitle,
    chapterContent: chapterContent,
  );
}

Future<void> cleanupBookSample({required String chapterId}) async {
  final db = PowerSyncService().db;
  try {
    await db.execute('DELETE FROM chapters WHERE id = ?', [chapterId]);
  } catch (_) {
    // best effort cleanup
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Editor posting + announcement history fetch',
    (tester) async {
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

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final marker = 'IT$stamp';
      final title = marker;
      final content = 'Announcement integration validation $marker';

      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        await AnnouncementRepository().createAnnouncement(
          title: title,
          content: content,
          userId: userId,
        );
        await tester.pump(const Duration(milliseconds: 900));

        await tapText(tester, 'Home');
        await openDrawerFromBottomMenu(tester);
        await tapText(tester, 'Announcements');
        await waitFor(
          tester,
          find.text('Announcements'),
          timeout: const Duration(seconds: 20),
        );
        await waitFor(
          tester,
          find.textContaining(marker),
          timeout: const Duration(seconds: 30),
        );
      } finally {
        await deleteAnnouncementsByTitle(title);
        await signOutBestEffort(tester);
      }
    },
    skip: !_hasEditorCreds && !_hasAdminCreds,
  );

  testWidgets('Book sample data fetch (books -> chapters -> reader)', (
    tester,
  ) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));

    await waitForAny(tester, [
      find.text('Menu'),
      find.text('Welcome Back'),
    ], timeout: const Duration(seconds: 45));

    if (_hasEditorCreds || _hasAdminCreds) {
      await signInViaApi(
        tester,
        candidates: [
          if (_hasEditorCreds) (_editorEmail, _editorPassword),
          if (_hasAdminCreds) (_adminEmail, _adminPassword),
        ],
      );
    } else {
      await signOutBestEffort(tester);
    }

    final sample = await seedBookSample();
    try {
      await tapText(tester, 'Home');
      await openDrawerFromBottomMenu(tester);
      await tapText(tester, 'Directory');

      await waitFor(
        tester,
        find.text('Khawlian Chanchin'),
        timeout: const Duration(seconds: 25),
      );
      await waitFor(
        tester,
        find.text(sample.bookTitle),
        timeout: const Duration(seconds: 30),
      );
      await scrollUntilTextVisible(
        tester,
        sample.chapterTitle,
        timeout: const Duration(seconds: 25),
      );
      await tapText(tester, sample.chapterTitle);

      await waitFor(
        tester,
        find.text('Read Story'),
        timeout: const Duration(seconds: 20),
      );
      await waitFor(
        tester,
        find.textContaining(sample.chapterContent),
        timeout: const Duration(seconds: 20),
      );
    } finally {
      await cleanupBookSample(chapterId: sample.chapterId);
      await Supabase.instance.client.auth.signOut();
    }
  });
}

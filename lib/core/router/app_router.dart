import 'package:go_router/go_router.dart';
import 'package:liankhawpui/features/news/presentation/news_manage_screen.dart';
import 'package:liankhawpui/features/news/presentation/news_edit_screen.dart';
import 'package:liankhawpui/features/news/domain/news.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liankhawpui/features/auth/presentation/auth_providers.dart';
import 'package:liankhawpui/features/auth/presentation/login_screen.dart';
import 'package:liankhawpui/features/splash/presentation/splash_screen.dart';
import 'package:liankhawpui/features/home/presentation/home_page.dart';
import 'package:liankhawpui/features/organization/presentation/organization_screen.dart';
import 'package:liankhawpui/features/organization/presentation/organization_detail_screen.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_list_screen.dart';
import 'package:liankhawpui/features/announcement/presentation/announcement_create_screen.dart';
import 'package:liankhawpui/features/news/presentation/news_list_screen.dart';
import 'package:liankhawpui/features/story/presentation/book_list_screen.dart';
import 'package:liankhawpui/features/story/presentation/chapter_list_screen.dart';
import 'package:liankhawpui/features/story/presentation/chapter_reader_screen.dart';
import 'package:liankhawpui/features/dashboard/presentation/dashboard_screen.dart';
import 'package:liankhawpui/features/dashboard/presentation/manage_users_screen.dart';
import 'package:liankhawpui/features/auth/presentation/profile_screen.dart';
import 'package:liankhawpui/features/auth/presentation/edit_profile_screen.dart';
import 'package:liankhawpui/features/auth/domain/user_role.dart';
import 'package:liankhawpui/features/settings/presentation/settings_screen.dart';
import 'package:liankhawpui/features/auth/presentation/forgot_password_screen.dart';
import 'package:liankhawpui/features/auth/presentation/registration_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/announcement',
        builder: (context, state) => const AnnouncementListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const AnnouncementCreateScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsListScreen(),
      ),
      GoRoute(
        path: '/book',
        builder: (context, state) => const BookListScreen(),
        routes: [
          GoRoute(
            path: ':bookId',
            builder: (context, state) {
              final bookId = state.pathParameters['bookId']!;
              return ChapterListScreen(bookId: bookId);
            },
            routes: [
              GoRoute(
                path: 'chapter/:chapterId',
                builder: (context, state) {
                  final chapterId = state.pathParameters['chapterId']!;
                  return ChapterReaderScreen(chapterId: chapterId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/organization',
        builder: (context, state) => const OrganizationScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OrganizationDetailScreen(orgId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        redirect: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user.role != UserRole.admin && user.role != UserRole.editor) {
            return '/';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              final role = filter == 'guest'
                  ? UserRole.guest
                  : null; // Can extend for other roles
              return ManageUsersScreen(initialRole: role);
            },
          ),
          GoRoute(
            path: 'news',
            builder: (context, state) => const NewsManageScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const NewsEditScreen(),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) {
                  final news = state.extra as News?;
                  return NewsEditScreen(news: news);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Add more routes here
    ],
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isLoggedIn = !user.isGuest;
      final isLoggingIn = state.uri.toString() == '/login';

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

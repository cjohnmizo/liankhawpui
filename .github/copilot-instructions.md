# Copilot Instructions for Liankhawpui

## Quick Context

**Liankhawpui** is a Flutter news/content directory app with offline-first capabilities. Key architecture: **feature-first + clean architecture layers** (data/domain/presentation) with **Riverpod 2.x** state management and **PowerSync + Supabase** for backend sync.

---

## Architecture Patterns

### Feature-First Structure
Each feature lives in `lib/features/{feature_name}/` with three layers:
- **`data/`**: Repositories, local database operations, HTTP clients. Single-purpose, no business logic.
- **`domain/`**: Entities, value objects. Pure Dart, framework-agnostic.
- **`presentation/`**: Screens, widgets, Riverpod providers. Consumer widgets for state access.

**Example**: News feature has `news/data/news_repository.dart` → `news/domain/news.dart` → `news/presentation/news_list_screen.dart`

### Shared Core Layer
`lib/core/` contains cross-cutting concerns:
- **`services/`**: `SupabaseService`, `PowerSyncService` (singletons initialized in `main()`)
- **`router/`**: `app_router.dart` defines all routes with `GoRouter` and role-based guards
- **`theme/`**: `app_theme.dart`, `app_colors.dart`, `text_styles.dart` — centralized design tokens
- **`config/`**: `EnvConfig` (reads `.env` file) and `AppAssets` (asset paths)

---

## State Management (Riverpod 2.x)

### Provider Patterns
- **Simple data**: `Provider<T>`
- **Async operations**: `FutureProvider<T>` or `StreamProvider<T>` (never async `Future<T>` directly in providers)
- **Mutable state**: `StateNotifierProvider<NotifierClass, StateType>`
- **Code generation**: Use `@riverpod` annotations and run `dart run build_runner watch`

### Reading Providers
- In **screens/widgets**: Use `ConsumerWidget` + `ref.watch()`
- **Combine providers**: Use `providers` parameter in `FutureProvider` dependency
- Never access providers outside Flutter context — use `SupabaseService.client` directly for backend calls

**Example** (auth_providers.dart):
```dart
@riverpod
Future<AppUser?> currentUser(CurrentUserRef ref) async {
  final auth = SupabaseService.client.auth;
  // fetch user from Supabase
}

final authRepositoryProvider = Provider((ref) => AuthRepository(SupabaseService.client));
```

---

## Backend Integration

### Supabase + PowerSync Workflow
1. **Authentication**: All auth through `Supabase.instance.client.auth`
2. **Offline sync**: PowerSync syncs Supabase changes ↔ local SQLite (schema in `lib/data/local/db_schema.dart`)
3. **Access pattern**: 
   - UI → Riverpod providers → Repositories
   - Repositories read from **PowerSync DB** `PowerSyncService().db` for offline queries
   - Write operations sync back to Supabase via `SupabaseConnector`

### Database Schema
All tables defined in `lib/data/local/db_schema.dart` with PowerSync `Table()` and `Column()` builders. Schema follows naming: `snake_case` columns, UUID for IDs, `created_at`/`updated_at` timestamps.

**Key tables**: `announcements`, `news`, `organizations`, `office_bearers`, `users`, `profiles`

---

## Navigation & Routing

**GoRouter** (`lib/core/router/app_router.dart`) manages navigation with auth state guards:
- Routes update reactively based on `authRepository.authStateChanges`
- **Guest routes**: `/login`, `/register`, `/forgot-password` (redirect home if logged in)
- **Admin routes**: `/dashboard`, `/news/manage` (check `user_role` in guards)
- Splash screen handles initialization before routing

When adding routes: Update `app_router.dart` with new `GoRoute` and ensure role-based redirect logic.

---

## Theme & Styling

### Centralized Design System
- **Colors**: `lib/core/theme/app_colors.dart` (light/dark variants)
- **Text Styles**: `lib/core/theme/text_styles.dart` (named: `headlineLarge`, `bodyMedium`, etc.)
- **Active theme**: `ref.watch(themeModeProvider)` returns `ThemeMode` state
- **Dark mode**: Fully supported in `app_theme.dart` — always test both themes

Use `GoogleFonts` for typography (configured in `pubspec.yaml`).

---

## Key Dependencies & Versions

| Package | Purpose | Notes |
|---------|---------|-------|
| `flutter_riverpod: ^2.4.9` | State management | Use code generation, watch for nullability |
| `go_router: ^12.1.0` | Navigation | Auth-reactive routing guards |
| `supabase_flutter: ^2.3.0` | Backend auth/DB | Initialize in `main()` before `ProviderScope` |
| `powersync: ^1.8.0` | Offline sync | Requires `SQLite`, schema in `db_schema.dart` |
| `freezed_annotation` + `json_serializable` | Data modeling | Run `build_runner` to generate models |
| `flutter_dotenv: ^6.0.0` | Env vars | Load in `main()` before service init |

---

## Build & Development Commands

```bash
# Install deps
flutter pub get

# Code generation (models, providers, routing)
dart run build_runner watch

# Format & lint
dart format .
dart analyze

# Run app
flutter run                    # Choose device
flutter run -d chrome          # Web preview
flutter run --profile          # Performance testing

# Build
flutter build apk              # Android
flutter build ipa              # iOS
```

---

## Project-Specific Conventions

### File Naming
- Screens/widgets: `{feature}_screen.dart` or `{feature}_page.dart`
- Providers: `{feature}_providers.dart` (centralized)
- Repositories: `{feature}_repository.dart`
- Models: `{entity}.dart` (use Freezed for immutability)

### Imports
- Always use relative imports within features: `../data/`, `../../core/`
- Use absolute imports for cross-feature: `package:liankhawpui/features/auth/`

### Null Safety & Type Safety
- All code is null-safe — use `?` and `late` intentionally
- Avoid `dynamic` — use proper types even for maps/lists
- Models use Freezed: `@freezed class Entity with _$Entity {}`

### Error Handling
- Repositories catch and wrap errors: Return `Result<T>` or throw custom exceptions
- UI handles provider `AsyncValue.when(data, loading, error)`
- Services (Supabase, PowerSync) throw on critical failures; logged in `main()`

---

## Testing Patterns

- **Unit tests**: Test repositories (mock dependencies), use `test` package
- **Widget tests**: Test screens with `ProviderContainer` and fake providers
- **Golden tests**: For UI regression (`.png` snapshots in `test/goldens/`)
- Coverage target: 70%+ (checked in CI)

Tests live in `test/` mirroring `lib/` structure.

---

## Critical Initialization Sequence

**This must happen in `main()` before `runApp()`:**

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `dotenv.load(fileName: ".env")` — Load environment variables
3. `SupabaseService.initialize()` — Supabase auth/client
4. `PowerSyncService().initialize()` — Offline sync (depends on Supabase being ready)
5. `runApp()` wrapped in `ProviderScope`

Failure here crashes the app before UI renders.

---

## Common Gotchas

1. **PowerSync sync**: Requires active Supabase auth session. Unauthorized writes are silently dropped.
2. **Riverpod invalidation**: Don't over-invalidate providers — causes unnecessary rebuilds. Use `.select()` for partial state.
3. **GoRouter guards**: Redirect loops possible if not careful with conditional logic. Test with multiple roles.
4. **Asset paths**: Update `pubspec.yaml` after adding images/icons — `flutter pub get` is needed.
5. **Env vars**: `.env` is ignored in this repo, but never commit secrets or keys to tracked files.

---

## When to Ask for Clarification

- Exact column names in new DB tables (check `db_schema.dart` + Supabase schema)
- Role-based permission logic (see `lib/features/auth/domain/user_role.dart`)
- Feature boundaries (which data belongs to which feature's repository)
- Deep linking structure (see `app_router.dart` for patterns)

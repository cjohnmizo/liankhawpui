# Liankhawpui

![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-Proprietary-red)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)

**⚠️ PROPRIETARY SOURCE CODE. DO NOT DISTRIBUTE.**

Khawlian News Directory App.

## License
Proprietary. All rights reserved. See `LICENSE` for details.

## 📸 Screenshots

| Home Screen | News Feed | Article Detail |
|:-----------:|:---------:|:--------------:|
| <img src="assets/screenshots/home.png" width="200" /> | <img src="assets/screenshots/news.png" width="200" /> | <img src="assets/screenshots/article.png" width="200" /> |

*(Add screenshots to `assets/screenshots/` to display them here)*

## ✨ Features

- **📰 News Feed**: Stay updated with the latest local news and articles.
- **📢 Announcements**: Important community notices and official updates.
- **📖 Story & Books**: Read community stories, books, and chapters directly in the app.
- **🏢 Organizations**: A directory of local organizations and their details.
- **👤 User Management**: Guest and Member roles with profile management.
- **⚙️ Admin Dashboard**: Comprehensive tools for content creators to manage news, users, and approvals.
- **🌑 Dark Mode**: Fully supported system-wide dark theme.
- **📴 Offline First**: Powered by **PowerSync** for seamless offline access.
- **📶 Low Data Mode**: Lower image bandwidth and upload size for weak internet.
- **🔄 Sync Transparency**: Settings show sync status, upload queue, and manual sync.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK 3.10+)
- **State Management**: [Riverpod](https://riverpod.dev/) (2.x) with code generation
- **Backend**: [Supabase](https://supabase.com/) (Auth, Database)
- **Offline Sync**: [PowerSync](https://powersync.com/) (SQLite based sync)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Notifications**: [OneSignal](https://onesignal.com/)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed
- A Supabase project
- A PowerSync instance linked to Supabase

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-org-or-user/liankhawpui.git
   cd liankhawpui
   ```

2. **Environment Setup**:
   Copy `.env.example` to `.env` and keep only client-safe keys in it:
   ```env
   SUPABASE_URL=...
   SUPABASE_ANON_KEY=...
   POWERSYNC_URL=...
   POWERSYNC_TOKEN_FUNCTION=powersync-token
   ONESIGNAL_APP_ID=...
   ```

   `SUPABASE_SERVICE_ROLE_KEY` and `ONESIGNAL_REST_API_KEY` must stay server-side only.
   For Android push delivery, also configure Firebase Sender ID in OneSignal
   Dashboard under `App Settings -> Android -> Configuration`.

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Deploy Backend Functions (Recommended for production)**:
   ```bash
   supabase functions deploy powersync-token --no-verify-jwt
   supabase functions deploy send-notification --no-verify-jwt
   supabase functions deploy admin-users
   ```
   Function configuration details: [`supabase/functions/README.md`](supabase/functions/README.md)

5. **Deploy PowerSync Sync Rules (Required)**:
   If sync status shows `PSYNC_S2302: No sync rules available`, open your
   PowerSync dashboard and deploy the rules from
   [`powersync/sync-rules.yaml`](powersync/sync-rules.yaml).

6. **Run the App**:
   ```bash
   flutter run
   ```

## Android Release Signing

1. Copy the template and fill real values:
   ```bash
   cp android/key.properties.example android/key.properties
   ```
2. Put your keystore at `android/app/upload-keystore.jks` (or change `storeFile`).
3. Build signed release artifacts:
   ```bash
   flutter build apk --release --split-per-abi
   flutter build appbundle --release
   ```

If `android/key.properties` is missing, release builds fall back to debug signing.

## Integration Testing

### Local emulator run

Guest functional smoke test:

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_functional_smoke_test.dart -d emulator-5554 --profile --dart-define=TEST_MODE=true
```

Role dashboard smoke tests (Editor/Admin):

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/role_dashboard_smoke_test.dart -d emulator-5554 --profile --dart-define=TEST_MODE=true --dart-define=TEST_EDITOR_EMAIL=editor@example.com --dart-define=TEST_EDITOR_PASSWORD=... --dart-define=TEST_ADMIN_EMAIL=admin@example.com --dart-define=TEST_ADMIN_PASSWORD=...
```

Data fetching smoke tests (posting + history + books/chapters):

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/data_fetching_smoke_test.dart -d emulator-5554 --profile --dart-define=TEST_MODE=true --dart-define=TEST_EDITOR_EMAIL=editor@example.com --dart-define=TEST_EDITOR_PASSWORD=... --dart-define=TEST_ADMIN_EMAIL=admin@example.com --dart-define=TEST_ADMIN_PASSWORD=...
```

If role credentials are not provided, role tests are skipped.

### GitHub Actions CI

Workflow: `.github/workflows/flutter-integration-android.yml`

Required repository secrets:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `SUPABASE_ANON_KEY`
- `POWERSYNC_URL`
- `POWERSYNC_TOKEN_FUNCTION`
- `ONESIGNAL_APP_ID`
- `TEST_EDITOR_EMAIL` (required for CI role smoke tests)
- `TEST_EDITOR_PASSWORD` (required for CI role smoke tests)
- `TEST_ADMIN_EMAIL` (required for CI role smoke tests)
- `TEST_ADMIN_PASSWORD` (required for CI role smoke tests)

CI now always runs admin create/update/delete user flow with `TEST_ADMIN_USERS_FLOW=true`.

## 📂 Project Structure

The project follows a feature-first architecture:

```
lib/
├── core/                # Shared logic, configs, theme, and widgets
├── features/            # Feature-specific modules
│   ├── news/            # content: data, domain, presentation
│   ├── auth/            # Login, Registration, State
│   ├── story/           # Books and Chapter reader
│   ├── dashboard/       # Admin tools
│   └── ...
└── main.dart            # Entry point
```

## 🛡️ Security

We take security seriously. If you discover a vulnerability, please check our [Security Policy](SECURITY.md) for reporting guidelines.

Backend setup notes:
- RLS baseline: [`supabase/sql/rls_policies.sql`](supabase/sql/rls_policies.sql)
- Edge function guidance: [`supabase/README.md`](supabase/README.md)

## 🔒 License

**Proprietary Software.**
Copyright (c) 2026 C. John. All Rights Reserved.
Unauthorized copying of this file, via any medium is strictly prohibited.
See `LICENSE` file for details.

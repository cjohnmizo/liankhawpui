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
   git clone https://github.com/yourusername/Liankhawpui.git
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

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Deploy Backend Functions (Recommended for production)**:
   ```bash
   supabase functions deploy powersync-token
   supabase functions deploy send-notification
   ```
   Function configuration details: [`supabase/functions/README.md`](supabase/functions/README.md)

5. **Run the App**:
   ```bash
   flutter run
   ```

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

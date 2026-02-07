# Liankhawpui

**⚠️ PROPRIETARY SOURCE CODE. DO NOT DISTRIBUTE.**

Khawlian News Directory App.

## License
Proprietary. All rights reserved. See `LICENSE` for details.

## Getting Started

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd liankhawpui
   ```

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
   Create a `.env` file in the root directory and add your keys:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   POWERSYNC_URL=your_powersync_url
   ONESIGNAL_APP_ID=your_onesignal_app_id
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
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

## 🔒 License

**Proprietary Software.**
Copyright (c) 2026 C. John. All Rights Reserved.
Unauthorized copying of this file, via any medium is strictly prohibited.
See `LICENSE` file for details.

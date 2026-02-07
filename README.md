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

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure PowerSync:
   Ensure your `powersync.config.toml` is set up and linked to your PowerSync instance.

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

The project follows a standard Flutter architecture with clear separation of concerns:

```
lib/
├── core/
│   ├── router/          # App navigation and routing
│   ├── theme/           # App theme and colors
│   └── widgets/         # Reusable widgets
├── features/
│   ├── auth/            # Authentication flows (Login, etc.)
│   ├── home/            # Main home screen and navigation
│   ├── organization/    # Organization listing and details
│   └── splash/          # Splash screen and startup logic
└── main.dart            # App entry point

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:liankhawpui/core/theme/app_theme.dart';
import 'package:liankhawpui/core/theme/theme_provider.dart';
import 'package:liankhawpui/core/services/supabase_service.dart';
import 'package:liankhawpui/core/services/powersync_service.dart';
import 'package:liankhawpui/core/router/app_router.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    // Initialize Backend Services
    await SupabaseService.initialize();
    await PowerSyncService().initialize();

    runApp(const ProviderScope(child: LiankhawpuiApp()));
  } catch (e) {
    debugPrint('CRITICAL: Initialization failed: $e');
    // Run a error app or rethrow depending on needs, but printing helps debugging
  }
}

class LiankhawpuiApp extends ConsumerWidget {
  const LiankhawpuiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Liankhawpui',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

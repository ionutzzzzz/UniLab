import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:context_menus/context_menus.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'shell/main_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const UniLabApp(),
      ),
    ),
  );
}

class UniLabApp extends StatelessWidget {
  const UniLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkTheme = AppTheme.createDarkTheme();
    final lightTheme = AppTheme.createLightTheme();

    return MaterialApp(
      title: 'UniLab',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: ContextMenuOverlay(child: const MainShell()),
    );
  }
}

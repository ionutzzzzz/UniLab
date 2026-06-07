import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart' as p_provider;
import 'package:window_manager/window_manager.dart';
import 'package:context_menus/context_menus.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart' as dmw;
import 'dart:convert';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'features/workspace/state/workspace_providers.dart' as workspace_prov;
import 'providers/riverpod_providers.dart' as rp;
import 'shell/main_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/plots_window_screen.dart';
import 'screens/simulation_window_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final windowController = await dmw.WindowController.fromCurrentEngine();
  final argumentsStr = windowController.arguments;

  Map<String, dynamic> argument = {};
  String windowType = 'main';

  if (argumentsStr.isNotEmpty) {
    try {
      final parsed = jsonDecode(argumentsStr) as Map<String, dynamic>;
      argument = parsed;
      windowType = parsed['type'] as String? ?? 'main';
    } catch (e) {
      windowType = 'main';
    }
  }

  // ------------------------------------------------------------------
  // SECONDARY WINDOW (SIMULATION)
  // ------------------------------------------------------------------
  if (windowType == 'simulation') {
    runApp(
      ProviderScope(
        child: p_provider.MultiProvider(
          providers: [
            p_provider.ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              final settingsProvider = p_provider.Provider.of<SettingsProvider>(context);
              final settings = settingsProvider.settings;
              final darkTheme = AppTheme.createTheme(settings, Brightness.dark);
              final lightTheme = AppTheme.createTheme(
                settings,
                Brightness.light,
              );

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: settings.themeMode,
                theme: lightTheme,
                darkTheme: darkTheme,
                home: SimulationWindowScreen(
                  windowId: windowController.windowId.toString(),
                  args: argument,
                ),
              );
            },
          ),
        ),
      ),
    );
    return;
  }

  // ------------------------------------------------------------------
  // SECONDARY WINDOW (PLOTS)
  // ------------------------------------------------------------------
  if (windowType == 'plots') {
    runApp(
      ProviderScope(
        child: p_provider.MultiProvider(
          providers: [
            p_provider.ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              final settingsProvider = p_provider.Provider.of<SettingsProvider>(context);
              final settings = settingsProvider.settings;
              final darkTheme = AppTheme.createTheme(settings, Brightness.dark);
              final lightTheme = AppTheme.createTheme(
                settings,
                Brightness.light,
              );

              return MaterialApp(
                debugShowCheckedModeBanner: false,
                themeMode: settings.themeMode,
                theme: lightTheme,
                darkTheme: darkTheme,
                home: PlotsWindowScreen(
                  windowId: windowController.windowId.toString(),
                  args: argument,
                ),
              );
            },
          ),
        ),
      ),
    );
    return;
  }

  // ------------------------------------------------------------------
  // MAIN WINDOW
  // ------------------------------------------------------------------
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows)) {
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
      
      // Set the window icon
      if (!kIsWeb) {
        if (Platform.isWindows) {
          await windowManager.setIcon('windows/runner/resources/app_icon.ico');
        } else if (Platform.isLinux) {
          try {
            final exePath = File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
            final exeDir = File(exePath).parent.path;
            final iconPath = p.join(exeDir, 'data', 'flutter_assets', 'assets', 'logo.png');
            if (await File(iconPath).exists()) {
              await windowManager.setIcon(iconPath);
            }
          } catch (e) {
            debugPrint('Error setting window icon: $e');
          }
        }
      }
    });
  }

  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          return p_provider.MultiProvider(
            providers: [
              p_provider.ChangeNotifierProvider(create: (_) => SettingsProvider()),
              p_provider.ChangeNotifierProxyProvider<SettingsProvider, AppProvider>(
                create: (_) => AppProvider(
                  onVariablesUpdated: (vars) {
                    ref
                        .read(
                          workspace_prov.workspaceVariablesProvider.notifier,
                        )
                        .replaceAll(vars);
                  },
                  onPlotsUpdated: (plots) {
                    ref.read(rp.plotGalleryProvider.notifier).replaceAll(plots);
                  },
                ),
                update: (context, settings, app) => app!..updateSettings(settings),
              ),
            ],
            child: child,
          );
        },
        child: const UniLabApp(),
      ),
    ),
  );
}

class UniLabApp extends StatelessWidget {
  const UniLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = p_provider.Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    final darkTheme = AppTheme.createTheme(settings, Brightness.dark);
    final lightTheme = AppTheme.createTheme(settings, Brightness.light);

    return MaterialApp(
      title: 'UniLab',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: ContextMenuOverlay(child: const MainShell()),
    );
  }
}

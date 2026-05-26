import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'package:context_menus/context_menus.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const UniLabApp(),
    ),
  );
}

class UniLabApp extends StatelessWidget {
  const UniLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Professional dark theme inspired by MATLAB 2025, VS Code, and Office
    final darkTheme = ThemeData(
      useMaterial3: false, // Disabling Material 3 for a flatter, tighter desktop look
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF007ACC), // Professional Desktop Blue (MATLAB style)
      scaffoldBackgroundColor: const Color(0xFF1E1E1E), // Editor/Console Background
      cardColor: const Color(0xFF252526), // Sidebar Background
      canvasColor: const Color(0xFF2D2D30), // Ribbon/Toolbar Background
      dividerColor: const Color(0xFF333333), // Subtler Borders and Dividers
      hoverColor: const Color(0xFF3E3E42), // Subtle button hover state
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF007ACC),
        surface: Color(0xFF252526),
        onSurface: Color(0xFFCCCCCC),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          bodyMedium: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
          bodySmall: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFCCCCCC), size: 16),
    );

    return MaterialApp(
      title: 'UniLab',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: darkTheme,
      darkTheme: darkTheme,
      home: ContextMenuOverlay(
        child: MainScreen(),
      ),
    );
  }
}
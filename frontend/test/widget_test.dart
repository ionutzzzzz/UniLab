// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unilab/main.dart';
import 'package:unilab/providers/settings_provider.dart';
import 'package:unilab/providers/app_provider.dart';
import 'package:unilab/features/workspace/state/workspace_providers.dart' as workspace_prov;
import 'package:unilab/providers/riverpod_providers.dart' as rp;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('UniLab App smoke test', (WidgetTester tester) async {
    // Set a larger surface size to avoid overflows (UniLab is a desktop app)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame.
    // Note: UniLabApp needs to be wrapped in ProviderScope and MultiProvider
    // as it relies on both Riverpod and Provider for state management.
    await tester.pumpWidget(
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
              child: const UniLabApp(),
            );
          },
        ),
      ),
    );

    // Initial pump to allow providers to initialize
    await tester.pumpAndSettle();

    // Verify that the welcome screen is shown with the "UniLab" title.
    expect(find.text('UniLab'), findsAtLeast(1));
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
    
    // Check for action items
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('Open Project'), findsOneWidget);
  });
}

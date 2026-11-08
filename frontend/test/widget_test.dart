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
import 'package:unilab/models/models.dart';
import 'package:unilab/models/editor_models.dart';
import 'package:unilab/providers/settings_provider.dart';
import 'package:unilab/providers/app_provider.dart';
import 'package:unilab/core/commands/commands_registration.dart';
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

  test('UserSettings and PlotData serialize and copyWith new fields', () {
    final settings = UserSettings();
    expect(settings.glassmorphismEnabled, isTrue);
    expect(settings.plotShowGrid, isTrue);
    expect(settings.plotShowLabels, isTrue);
    expect(settings.plotShowLegend, isTrue);

    final updated = settings.copyWith(
      glassmorphismEnabled: false,
      plotShowGrid: false,
      plotShowLegend: false,
    );
    expect(updated.glassmorphismEnabled, isFalse);
    expect(updated.plotShowGrid, isFalse);
    expect(updated.plotShowLegend, isFalse);

    final plot = PlotData(
      title: 'Figure 1',
      type: 'line',
      xData: const [1, 2, 3],
      yData: const [4, 5, 6],
      xlabel: 'Time (s)',
      ylabel: 'Amplitude',
      showGrid: true,
      showLegend: true,
    );
    final json = plot.toJson();
    final roundTrip = PlotData.fromJson(json);
    expect(roundTrip.xlabel, 'Time (s)');
    expect(roundTrip.ylabel, 'Amplitude');
    expect(roundTrip.showGrid, isTrue);
    expect(roundTrip.showLegend, isTrue);
  });

  test('AppProvider script analysis, blocks, split editor, and help routing', () async {
    final provider = AppProvider();
    await provider.createProjectFile(
      'signal_demo.m',
      'function y = compute_wave(x)\n  y = sin(x) + cos(x);\nend\nx = linspace(0, 10, 100);\ny = compute_wave(x);\nplot(x, y);',
    );

    expect(provider.activeFile?.name, 'signal_demo.m');
    expect(provider.isWelcomeMode, isFalse);

    final blocks = provider.parseExecutableBlocks(provider.activeFile!.content);
    expect(blocks.length, 4);
    expect(blocks.first['line'], 1);

    final deps = provider.analyzeDependencies();
    expect(deps['definedFunctions'], contains('compute_wave'));
    expect(deps['builtinCalls'], containsAll(['sin', 'cos', 'linspace', 'plot']));

    provider.addNewFile();
    expect(provider.openFiles.length, 2);

    provider.toggleSplitEditor();
    expect(provider.isSplitEditor, isTrue);
    expect(provider.secondaryFile, isNotNull);

    provider.openHelpTopic('intro');
    expect(provider.selectedWorkspaceSegment, 'Help');
    expect(provider.requestedHelpTopic, 'intro');

    provider.closeOtherFiles(0);
    expect(provider.openFiles.length, 1);

    provider.closeAllFiles();
    expect(provider.openFiles, isEmpty);
    expect(provider.isSplitEditor, isFalse);
  });

  test('CommandRegistry registers all core IDE commands', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final registry = container.read(commandRegistryProvider);
    final ids = registry.getAll().map((c) => c.id).toSet();
    expect(
      ids,
      containsAll([
        'file.new',
        'file.open',
        'file.openFolder',
        'file.save',
        'file.saveAs',
        'file.importData',
        'file.exportPdf',
        'file.exportPython',
        'file.exportHtml',
        'file.print',
        'run.run',
        'run.stop',
        'editor.find',
        'editor.replace',
        'editor.gotoLine',
        'editor.autoIndent',
        'editor.comment',
        'workspace.clear',
        'console.clear',
        'view.toggleExplorer',
        'view.toggleWorkspace',
        'view.toggleConsole',
        'view.splitEditor',
        'view.resetLayout',
        'view.commandOnly',
        'backend.restart',
      ]),
    );
  });
}

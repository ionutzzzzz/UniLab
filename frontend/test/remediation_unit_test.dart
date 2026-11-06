import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unilab/models/editor_models.dart';
import 'package:unilab/models/models.dart';
import 'package:unilab/core/layout/shell_layout_state.dart';
import 'package:unilab/theme/ui_theme.dart';
import 'package:unilab/theme/ui_decorations.dart';
import 'package:unilab/widgets/ui_badge.dart';

void main() {
  group('PlotData & Models JSON parsing', () {
    test('PlotData.fromJson parses valid and malformed data safely', () {
      final json1 = {
        'title': 'Test Plot',
        'type': 'line',
        'x_data': [1, 2, 3.5, null],
        'y_data': [10.0, 20.0, 30.0, 40.0],
        'createdAt': '2026-11-06T20:00:00.000Z',
      };

      final plot = PlotData.fromJson(json1);
      expect(plot.title, 'Test Plot');
      expect(plot.type, 'line');
      expect(plot.xData, [1.0, 2.0, 3.5, 0.0]);
      expect(plot.yData, [10.0, 20.0, 30.0, 40.0]);

      // Malformed / empty json
      final plot2 = PlotData.fromJson({});
      expect(plot2.title, 'Figure');
      expect(plot2.xData, isEmpty);
      expect(plot2.yData, isEmpty);
    });

    test('ExecutionResult.fromJson safely handles nulls and plot_figures casts', () {
      final json = {
        'success': true,
        'stdout': 'ans = 42\n',
        'stderr': '',
        'execution_time': 0.05,
        'variables_snapshot': {'ans': {'name': 'ans', 'type': 'double', 'size': [1, 1], 'value': '42'}},
        'plots': ['fig1.png', null, 123],
        'extra': {
          'plot_figures': [1, null, '3'],
        },
      };

      final result = ExecutionResult.fromJson(json);
      expect(result.success, true);
      expect(result.stdout, 'ans = 42\n');
      expect(result.plots.length, 3);
      expect(result.plots[0].fileName, 'fig1.png');
      expect(result.plots[1].fileName, '');
      expect(result.plots[2].fileName, '123');
      expect(result.variables.containsKey('ans'), true);
    });
  });

  group('Find & Replace Logic', () {
    test('Regex matching correctly captures match length and positions', () {
      final text = 'function alpha = calculate(alpha_input)\n  alpha = alpha * 2;\nend';
      final query = r'alpha\w*';
      final regex = RegExp(query, caseSensitive: false);
      final matches = regex.allMatches(text).toList();

      expect(matches.length, 4);
      expect(matches[0].start, 9);
      expect(text.substring(matches[0].start, matches[0].end), 'alpha');
      expect(text.substring(matches[1].start, matches[1].end), 'alpha_input');
      expect(text.substring(matches[2].start, matches[2].end), 'alpha');
      expect(text.substring(matches[3].start, matches[3].end), 'alpha');
    });

    test('Case-sensitive search distinguishes casing', () {
      final text = 'Alpha alpha ALPHA';
      final regexSensitive = RegExp('alpha', caseSensitive: true);
      final regexInsensitive = RegExp('alpha', caseSensitive: false);

      expect(regexSensitive.allMatches(text).length, 1);
      expect(regexInsensitive.allMatches(text).length, 3);
    });
  });

  group('ShellLayoutState', () {
    test('isCommandOnlyMode and collapse logic decouple correctly', () {
      const state1 = ShellLayoutState(
        showLeftPanel: false,
        showRightPanel: false,
        showBottomPanel: true,
        isCommandOnlyMode: false,
      );

      // When sidebars are collapsed but not in command-only mode,
      // editor should remain visible at full width
      expect(state1.showLeftPanel, false);
      expect(state1.showRightPanel, false);
      expect(state1.isCommandOnlyMode, false);

      final state2 = state1.copyWith(isCommandOnlyMode: true);
      expect(state2.isCommandOnlyMode, true);
    });
  });

  group('Theme & UI Contrast', () {
    test('ShellDecorations.panelDecoration creates uniform border with borderRadius', () {
      final settings = UserSettings();
      final theme = createUiTheme(settings, Brightness.dark);
      final decoration = ShellDecorations.panelDecoration(theme);

      expect(decoration.borderRadius, isNotNull);
      expect(decoration.border, isNotNull);
      expect(decoration.border!.isUniform, true);
    });

    testWidgets('UiBadge warning variant has readable dark text contrast', (tester) async {
      final settings = UserSettings();
      final theme = createUiTheme(settings, Brightness.dark);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [theme]),
          home: const Scaffold(
            body: UiBadge(
              label: '3',
              variant: UiBadgeVariant.warning,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('3'));
      expect(textWidget.style?.color, const Color(0xFF1E1E1E));
    });
  });
}

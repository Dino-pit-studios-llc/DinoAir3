import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:crypto_dash/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Pseudocode Translator end-to-end translates to Python',
    (WidgetTester tester) async {
      // a) Launch the real app via main()
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // b) Open the drawer (prefer Key, fallback to tooltip)
      Finder drawerButton = find.byKey(const Key('open_drawer_button'));
      if (drawerButton.evaluate().isEmpty) {
        drawerButton = find.byTooltip('Open navigation menu');
      }
      expect(drawerButton, findsOneWidget, reason: 'Drawer/menu button not found');
      await tester.tap(drawerButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // c) Tap the drawer ListTile labeled “Pseudocode Translator”
      final translatorTile = find.text('Pseudocode Translator');
      expect(
        translatorTile,
        findsWidgets,
        reason: 'Drawer item "Pseudocode Translator" not found',
      );
      await tester.tap(translatorTile.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // d) Wait for translator screen to settle
      // The AppBar title for this route should be "Pseudocode Translator"
      expect(find.text('Pseudocode Translator'), findsWidgets);

      // e) Enter pseudocode into input field
      const pseudocode =
          'Given a list of integers, return the list sorted ascending and remove duplicates.';
      final inputFinder = find.byKey(const Key('translator_input_field'));
      expect(inputFinder, findsOneWidget, reason: 'Translator input field not found');
      await tester.ensureVisible(inputFinder);
      await tester.tap(inputFinder);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(inputFinder, pseudocode);
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // f) Open language dropdown and select “Python” (best-effort, continue if unavailable)
      final langSelector = find.byKey(const Key('translator_language_selector'));
      if (langSelector.evaluate().isNotEmpty) {
        await tester.tap(langSelector);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        final pythonChoice = find.text('Python');
        if (pythonChoice.evaluate().isNotEmpty) {
          await tester.tap(pythonChoice.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 800));
        } else {
          debugPrint('Language option "Python" not found. Continuing with default language.');
        }
      } else {
        debugPrint('Language selector not found. Continuing with default language.');
      }

      // g) Tap Translate button
      final translateBtn = find.byKey(const Key('translator_translate_button'));
      expect(translateBtn, findsOneWidget, reason: 'Translate button not found');
      await tester.tap(translateBtn);
      await tester.pump();

      // h) Await output in translation_output_panel with generous timeout (up to 30s)
      final outputPanel = find.byKey(const Key('translation_output_panel'));
      const maxWaitMs = 30000;
      var waitedMs = 0;
      while (outputPanel.evaluate().isEmpty && waitedMs < maxWaitMs) {
        await tester.pump(const Duration(milliseconds: 500));
        waitedMs += 500;
      }
      expect(
        outputPanel,
        findsOneWidget,
        reason: 'Timed out waiting for translation output panel (waited ${waitedMs}ms)',
      );

      // Extract translated text from SelectableText within the output panel
      final selectableFinder = find.descendant(
        of: outputPanel,
        matching: find.byType(SelectableText),
      );

      String captured = '';
      if (selectableFinder.evaluate().isNotEmpty) {
        final selectable = tester.widget<SelectableText>(selectableFinder.first);
        captured = selectable.data ?? selectable.textSpan?.toPlainText() ?? '';
      } else {
        // As a fallback, try to read any Text widget inside the output panel
        final textDesc = find.descendant(of: outputPanel, matching: find.byType(Text));
        if (textDesc.evaluate().isNotEmpty) {
          final textWidget = tester.widget<Text>(textDesc.first);
          captured = textWidget.data ?? textWidget.textSpan?.toPlainText() ?? '';
        }
      }

      // Diagnostics
      debugPrint('Translation output length: ${captured.length}');
      final preview = captured.length > 200 ? captured.substring(0, 200) : captured;
      debugPrint('Translation output preview: $preview');

      // Assertions: non-empty and contains likely Python tokens
      expect(captured.trim().isNotEmpty, true, reason: 'Translation output is empty');
      final looksLikePython = captured.contains('def ') || captured.contains('sorted(');
      expect(
        looksLikePython,
        true,
        reason:
            'Translation output does not appear to be Python (missing "def " or "sorted(" tokens)',
      );

      // i) Optional: best-effort history check if present (do not fail if absent)
      // This is optional and intentionally non-fatal to avoid flakiness if history UI is not visible.
      // Example (commented as placeholder):
      // final historyItem = find.textContaining('Translation Details');
      // if (historyItem.evaluate().isEmpty) {
      //   debugPrint('History entry not visible; continuing without failing.');
      // }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

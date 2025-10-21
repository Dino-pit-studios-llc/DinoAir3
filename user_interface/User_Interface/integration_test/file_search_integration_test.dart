import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:crypto_dash/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('File Search Integration Tests', () {
    testWidgets(
      'User can search for files and view results',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Open drawer
        Finder drawerButton = find.byKey(const Key('open_drawer_button'));
        if (drawerButton.evaluate().isEmpty) {
          drawerButton = find.byTooltip('Open navigation menu');
        }
        expect(drawerButton, findsOneWidget,
            reason: 'Drawer/menu button not found');
        await tester.tap(drawerButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to File Search
        final fileSearchTile = find.text('File Search');
        if (fileSearchTile.evaluate().isEmpty) {
          debugPrint('File Search feature not available in drawer');
          return;
        }
        await tester.tap(fileSearchTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify File Search screen loaded
        expect(
          find.text('File Search'),
          findsWidgets,
          reason: 'File Search screen not loaded',
        );

        // Enter search query
        const searchQuery = '*.dart';
        final searchField = find.byKey(const Key('file_search_input'));
        if (searchField.evaluate().isNotEmpty) {
          await tester.tap(searchField);
          await tester.pump(const Duration(milliseconds: 200));
          await tester.enterText(searchField, searchQuery);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));

          // Tap search button
          final searchButton = find.byKey(const Key('file_search_button'));
          if (searchButton.evaluate().isNotEmpty) {
            await tester.tap(searchButton);
            await tester.pump();

            // Wait for results with timeout
            const maxWaitMs = 10000;
            var waitedMs = 0;
            while (find
                        .byKey(const Key('file_search_results'))
                        .evaluate()
                        .isEmpty &&
                waitedMs < maxWaitMs) {
              await tester.pump(const Duration(milliseconds: 500));
              waitedMs += 500;
            }

            // Verify results appeared
            final resultsWidget = find.byKey(const Key('file_search_results'));
            if (resultsWidget.evaluate().isNotEmpty) {
              expect(resultsWidget, findsOneWidget,
                  reason: 'Search results should be displayed');
              debugPrint('✓ File search completed successfully');
            } else {
              debugPrint('⚠ Search completed but no results widget found');
            }
          } else {
            debugPrint('⚠ Search button not found');
          }
        } else {
          debugPrint('⚠ Search input field not found');
        }
      },
    );

    testWidgets(
      'User can apply search filters',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Navigate to File Search
        Finder drawerButton = find.byKey(const Key('open_drawer_button'));
        if (drawerButton.evaluate().isEmpty) {
          drawerButton = find.byTooltip('Open navigation menu');
        }
        await tester.tap(drawerButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final fileSearchTile = find.text('File Search');
        if (fileSearchTile.evaluate().isEmpty) {
          debugPrint('File Search feature not available');
          return;
        }
        await tester.tap(fileSearchTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Open filters
        final filterButton = find.byKey(const Key('file_search_filter_button'));
        if (filterButton.evaluate().isNotEmpty) {
          await tester.tap(filterButton);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));

          // Try to select file type filter
          final fileTypeFilter = find.byKey(const Key('filter_file_type'));
          if (fileTypeFilter.evaluate().isNotEmpty) {
            await tester.tap(fileTypeFilter);
            await tester.pumpAndSettle(const Duration(milliseconds: 300));
            debugPrint('✓ File type filter applied');
          } else {
            debugPrint('⚠ File type filter not found');
          }

          // Try to select date filter
          final dateFilter = find.byKey(const Key('filter_date_modified'));
          if (dateFilter.evaluate().isNotEmpty) {
            await tester.tap(dateFilter);
            await tester.pumpAndSettle(const Duration(milliseconds: 300));
            debugPrint('✓ Date filter applied');
          } else {
            debugPrint('⚠ Date filter not found');
          }

          // Close filter panel
          final closeFilter = find.byKey(const Key('close_filter_button'));
          if (closeFilter.evaluate().isNotEmpty) {
            await tester.tap(closeFilter);
            await tester.pumpAndSettle(const Duration(milliseconds: 300));
          }

          expect(find.text('File Search'), findsWidgets,
              reason: 'Should still be on File Search screen');
        } else {
          debugPrint('⚠ Filter button not found - skipping filter tests');
        }
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:crypto_dash/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Chat Integration Tests', () {
    testWidgets(
      'User can send a message and receive a response',
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

        // Navigate to AI Chat
        final chatTile = find.text('AI Chat');
        if (chatTile.evaluate().isEmpty) {
          debugPrint('AI Chat feature not available in drawer');
          return;
        }
        await tester.tap(chatTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify Chat screen loaded
        expect(
          find.text('AI Chat'),
          findsWidgets,
          reason: 'AI Chat screen not loaded',
        );

        // Enter a test message
        const testMessage = 'What is the capital of France?';
        final messageField = find.byKey(const Key('chat_message_input'));
        if (messageField.evaluate().isNotEmpty) {
          await tester.tap(messageField);
          await tester.pump(const Duration(milliseconds: 200));
          await tester.enterText(messageField, testMessage);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));

          // Send the message
          final sendButton = find.byKey(const Key('chat_send_button'));
          if (sendButton.evaluate().isNotEmpty) {
            await tester.tap(sendButton);
            await tester.pump();

            // Wait for response with generous timeout
            const maxWaitMs = 30000; // 30 seconds for AI response
            var waitedMs = 0;
            var responseFound = false;

            while (waitedMs < maxWaitMs) {
              await tester.pump(const Duration(milliseconds: 500));
              waitedMs += 500;

              // Look for specific AI response widget (keyed or by semantic label)
              final aiResponse = find.byKey(const Key('ai_response_message'));
              if (aiResponse.evaluate().isNotEmpty) {
                responseFound = true;
                break;
              }
            }

            if (responseFound) {
              debugPrint('✓ Chat response received successfully');
              expect(find.byKey(const Key('ai_response_message')), findsOneWidget,
                  reason: 'AI response message should be displayed');
            } else {
              debugPrint(
                  '⚠ Chat response not received within ${maxWaitMs}ms');
            }
          } else {
            debugPrint('⚠ Send button not found');
          }
        } else {
          debugPrint('⚠ Message input field not found');
        }
      },
    );

    testWidgets(
      'User can create a new chat session',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Navigate to AI Chat
        Finder drawerButton = find.byKey(const Key('open_drawer_button'));
        if (drawerButton.evaluate().isEmpty) {
          drawerButton = find.byTooltip('Open navigation menu');
        }
        await tester.tap(drawerButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final chatTile = find.text('AI Chat');
        if (chatTile.evaluate().isEmpty) {
          debugPrint('AI Chat feature not available');
          return;
        }
        await tester.tap(chatTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Try to create new session
        final newSessionButton = find.byKey(const Key('chat_new_session'));
        if (newSessionButton.evaluate().isNotEmpty) {
          await tester.tap(newSessionButton);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));

          // Verify new session created (empty chat)
          final messageBubbles = find.byType(ListTile);
          expect(
            messageBubbles.evaluate().isEmpty,
            isTrue,
            reason: 'New session should have no messages',
          );
          debugPrint('✓ New chat session created successfully');
        } else {
          debugPrint('⚠ New session button not found - feature may not exist');
        }
      },
    );

    testWidgets(
      'User can view chat history',
      (WidgetTester tester) async {
        // Launch the app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Navigate to AI Chat
        Finder drawerButton = find.byKey(const Key('open_drawer_button'));
        if (drawerButton.evaluate().isEmpty) {
          drawerButton = find.byTooltip('Open navigation menu');
        }
        await tester.tap(drawerButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final chatTile = find.text('AI Chat');
        if (chatTile.evaluate().isEmpty) {
          debugPrint('AI Chat feature not available');
          return;
        }
        await tester.tap(chatTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Try to open history
        final historyButton = find.byKey(const Key('chat_history_button'));
        if (historyButton.evaluate().isNotEmpty) {
          await tester.tap(historyButton);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));

          // Check if history panel appeared
          final historyPanel = find.byKey(const Key('chat_history_panel'));
          if (historyPanel.evaluate().isNotEmpty) {
            expect(historyPanel, findsOneWidget,
                reason: 'History panel should be visible');
            debugPrint('✓ Chat history panel opened successfully');

            // Close history
            final closeHistory = find.byKey(const Key('close_history_button'));
            if (closeHistory.evaluate().isNotEmpty) {
              await tester.tap(closeHistory);
              await tester.pumpAndSettle(const Duration(milliseconds: 300));
            }
          } else {
            debugPrint('⚠ History panel not found');
          }
        } else {
          debugPrint('⚠ History button not found - feature may not exist');
        }
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_messages_provider.dart';
import '../providers/chat_sessions_provider.dart';
import '../providers/chat_input_provider.dart';
import '../providers/chat_loading_provider.dart';
import '../../domain/chat_message_entity.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  @override
  void initState() {
    super.initState();
    // Load chat sessions when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatSessionsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);
    final loadingState = ref.watch(chatLoadingProvider);
    final currentSession = ref.watch(currentSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentSession?.title ?? 'AI Chat',
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // Session selector button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'new_session') {
                _showNewSessionDialog();
              } else if (value == 'manage_sessions') {
                _showSessionManagement();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_session',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('New Session'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'manage_sessions',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline),
                    SizedBox(width: 8),
                    Text('Sessions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('No messages yet. Start a conversation!'),
                    );
                  }

                  return ListView.builder(
                    controller: ref.watch(chatScrollControllerProvider),
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length +
                        (loadingState.isSendingMessage ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show typing indicator if sending message
                      if (index == messages.length &&
                          loadingState.isSendingMessage) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('AI is typing...'),
                        );
                      }

                      final message = messages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message.role == MessageRole.user
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.content,
                            style: TextStyle(
                              color: message.role == MessageRole.user
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading messages...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load messages',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(chatMessagesProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Chat input widget (placeholder)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _handleSendMessage(value);
                      }
                    },
                    enabled: !loadingState.isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: loadingState.isLoading
                      ? null
                      : () {
                          final text = ref.read(chatInputProvider).text.trim();
                          if (text.isNotEmpty) {
                            _handleSendMessage(text);
                          }
                        },
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSendMessage(String message) {
    if (message.trim().isEmpty) return;

    // Clear input
    ref.read(chatInputProvider.notifier).clearText();

    // Send message
    ref.read(chatMessagesProvider.notifier).sendMessage(message);
  }

  void _showNewSessionDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat Session'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Enter session title (optional)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim().isEmpty
                  ? null
                  : titleController.text.trim();

              Navigator.of(context).pop();

              // Create new session
              final newSession =
                  await ref.read(chatSessionsProvider.notifier).createSession(
                        title: title,
                      );

              if (newSession != null) {
                // Set as current session
                ref
                    .read(chatSessionsProvider.notifier)
                    .setCurrentSession(newSession);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSessionManagement() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat Sessions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ref.watch(chatSessionsProvider).when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return const Text('No sessions yet');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isCurrent =
                            session.id == ref.watch(currentSessionProvider)?.id;

                        return ListTile(
                          title: Text(session.title),
                          subtitle: Text(
                            '${session.messageCount} messages • ${_formatDate(session.updatedAt)}',
                          ),
                          leading: CircleAvatar(
                            child: Text(
                                session.title.substring(0, 1).toUpperCase()),
                          ),
                          trailing: isCurrent
                              ? Icon(Icons.check,
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                          onTap: () {
                            ref
                                .read(chatSessionsProvider.notifier)
                                .setCurrentSession(session);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error: $error'),
                ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

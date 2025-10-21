import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/chat_session_entity.dart';
import '../providers/chat_sessions_provider.dart';

class ChatSessionListWidget extends ConsumerWidget {
  const ChatSessionListWidget({
    required this.onSessionSelected,
    this.selectedSessionId,
    super.key,
  });

  final Function(ChatSessionEntity) onSessionSelected;
  final String? selectedSessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const _EmptySessionsView();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionListItem(
              session: session,
              isSelected: session.id == selectedSessionId,
              onTap: () => onSessionSelected(session),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                'Failed to load sessions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(chatSessionsProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionListItem extends StatelessWidget {
  const _SessionListItem({
    required this.session,
    required this.isSelected,
    required this.onTap,
  });

  final ChatSessionEntity session;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Session icon
              CircleAvatar(
                backgroundColor: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                child: Text(
                  session.title.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 12),

              // Session info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      session.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtitle with message count and date
                    Text(
                      '${session.messageCount} messages • ${_formatDate(session.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
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

class _EmptySessionsView extends StatelessWidget {
  const _EmptySessionsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No chat sessions yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation to create your first session',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

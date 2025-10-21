import 'package:flutter/material.dart';

class EmptyChatWidget extends StatelessWidget {
  const EmptyChatWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI Chat Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Welcome text
            Text(
              'Welcome to AI Chat',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Start a conversation with our AI assistant. Ask questions, get help, or just have a chat!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Feature highlights
            _FeatureHighlightsCard(theme: theme),

            const SizedBox(height: 24),

            // Sample prompts
            _SamplePromptsCard(theme: theme),

            const SizedBox(height: 24),

            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for better conversations',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _TipItem(
                    icon: Icons.chat_bubble_outline,
                    text:
                        'Be specific with your questions for better responses',
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _TipItem(
                    icon: Icons.edit_outlined,
                    text: 'Use clear and concise language',
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _TipItem(
                    icon: Icons.refresh_outlined,
                    text: 'Start a new session for different topics',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureHighlightsCard extends StatelessWidget {
  const _FeatureHighlightsCard({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Features',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _FeatureChip(
                icon: Icons.message_outlined,
                label: 'Smart responses',
                theme: theme,
              ),
              _FeatureChip(
                icon: Icons.history_outlined,
                label: 'Chat history',
                theme: theme,
              ),
              _FeatureChip(
                icon: Icons.multiple_stop_outlined,
                label: 'Multiple sessions',
                theme: theme,
              ),
              _FeatureChip(
                icon: Icons.copy_outlined,
                label: 'Copy messages',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SamplePromptsCard extends StatelessWidget {
  const _SamplePromptsCard({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💬 Try asking',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PromptChip(
                text: 'Explain quantum computing',
                theme: theme,
              ),
              _PromptChip(
                text: 'Write a haiku about coding',
                theme: theme,
              ),
              _PromptChip(
                text: 'Help me debug this error',
                theme: theme,
              ),
              _PromptChip(
                text: 'What\'s the weather like?',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.text,
    required this.theme,
  });

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({
    required this.icon,
    required this.text,
    required this.theme,
  });

  final IconData icon;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

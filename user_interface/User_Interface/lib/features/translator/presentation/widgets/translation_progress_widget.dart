import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/translator_loading_provider.dart';

class TranslationProgressWidget extends ConsumerWidget {
  const TranslationProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTranslating = ref.watch(isTranslatingProvider);
    final progress = ref.watch(translationProgressProvider);
    final error = ref.watch(translatorLoadingErrorProvider);

    if (!isTranslating && error == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isTranslating
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: isTranslating
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Progress indicator or error icon
          if (isTranslating)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 12),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          else
            Icon(
              Icons.error_outline,
              size: 16,
              color: theme.colorScheme.error,
            ),

          // Status text
          Expanded(
            child: Text(
              isTranslating
                  ? 'Translating pseudocode...'
                  : (error ?? 'Translation failed'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isTranslating
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Progress percentage (if available)
          if (isTranslating && progress > 0)
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.8),
              ),
            ),

          // Cancel button removed - not yet implemented in provider
          // TODO: Add cancel functionality when translation controller supports it

          // Retry button removed - not yet implemented in provider
          // TODO: Add retry functionality when translation controller supports it
        ],
      ),
    );
  }
}

// Linear progress indicator for streaming translations
class StreamingProgressWidget extends ConsumerWidget {
  const StreamingProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTranslating = ref.watch(isTranslatingProvider);
    final progress = ref.watch(translationProgressProvider);

    if (!isTranslating) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress text
          Text(
            'Generating translation...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 8),

          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 4,
            ),
          ),

          // Progress percentage
          if (progress > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${(progress * 100).toInt()}% complete',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Compact progress indicator for buttons
class CompactProgressIndicator extends ConsumerWidget {
  const CompactProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTranslating = ref.watch(isTranslatingProvider);

    if (!isTranslating) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 8),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// Progress indicator with estimated time
class TranslationProgressWithTimeWidget extends ConsumerWidget {
  const TranslationProgressWithTimeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTranslating = ref.watch(isTranslatingProvider);
    final progress = ref.watch(translationProgressProvider);

    if (!isTranslating) {
      return const SizedBox.shrink();
    }

    // Estimate remaining time based on progress
    final estimatedTotalTime = 3000; // 3 seconds in milliseconds
    final elapsedTime = (progress * estimatedTotalTime).toInt();
    final remainingTime = estimatedTotalTime - elapsedTime;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Translating...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                  Text(
                    _formatTime(remainingTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).ceil();
    if (seconds < 60) {
      return '$seconds second${seconds == 1 ? '' : 's'} remaining';
    } else {
      final minutes = (seconds / 60).floor();
      final remainingSeconds = seconds % 60;
      return '$minutes minute${minutes == 1 ? '' : 's'} $remainingSeconds second${remainingSeconds == 1 ? '' : 's'} remaining';
    }
  }
}

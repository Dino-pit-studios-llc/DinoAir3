import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_routes.dart';
import '../../domain/project_entity.dart';
import '../providers/project_detail_provider.dart';
import '../widgets/project_status_indicator_widget.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final ProjectEntity project;

  const ProjectDetailScreen({
    required this.project,
    super.key,
  });

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text(
          'Are you sure you want to delete this project? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(projectOperationsProvider.notifier).deleteProject(
            project.id,
          );
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final operationsState = ref.watch(projectOperationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push(
                AppRoutes.projectEditPath(project.id),
                extra: project,
              );
            },
            tooltip: 'Edit project',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context, ref),
            tooltip: 'Delete project',
          ),
        ],
      ),
      body: operationsState.when(
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (project.icon != null) ...[
                            Text(
                              project.icon!,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              project.name,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ProjectStatusIndicatorWidget(status: project.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              if (project.description.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(project.description),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Metadata
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.event,
                        label: 'Created',
                        value: DateFormat.yMMMd().add_jm().format(
                              project.createdAt,
                            ),
                      ),
                      if (project.updatedAt != project.createdAt)
                        _DetailRow(
                          icon: Icons.update,
                          label: 'Updated',
                          value: DateFormat.yMMMd().add_jm().format(
                                project.updatedAt,
                              ),
                        ),
                      if (project.color != null)
                        _DetailRow(
                          icon: Icons.palette,
                          label: 'Color',
                          value: project.color!,
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  project.color!.replaceAll('#', '0xFF'),
                                ),
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Tags
              if (project.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tags',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: project.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Custom Metadata
              if (project.metadata != null && project.metadata!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Fields',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...project.metadata!.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    entry.key,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    entry.value.toString(),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${error.toString()}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

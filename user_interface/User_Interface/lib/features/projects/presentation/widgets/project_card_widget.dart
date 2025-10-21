import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/project_entity.dart';
import 'project_status_indicator_widget.dart';

class ProjectCardWidget extends StatelessWidget {
  final ProjectEntity project;
  final VoidCallback onTap;

  const ProjectCardWidget({
    required this.project,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: project.color != null
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Color(
                        int.parse(project.color!.replaceAll('#', '0xFF')),
                      ),
                      width: 4,
                    ),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with icon
                Row(
                  children: [
                    if (project.icon != null) ...[
                      Text(
                        project.icon!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        project.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ProjectStatusIndicatorWidget(
                      status: project.status,
                      compact: true,
                    ),
                  ],
                ),

                // Description
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Tags
                if (project.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: project.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    }).toList()
                      ..addAll(
                        project.tags.length > 3
                            ? [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    '+${project.tags.length - 3}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ]
                            : [],
                      ),
                  ),
                ],

                // Footer with date
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated ${dateFormatter.format(project.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

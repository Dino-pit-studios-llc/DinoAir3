import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/project_entity.dart';
import '../providers/project_form_provider.dart';

class ProjectFormScreen extends ConsumerStatefulWidget {
  final ProjectEntity? project;

  const ProjectFormScreen({
    this.project,
    super.key,
  });

  @override
  ConsumerState<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends ConsumerState<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? '',
    );
    _tagController = TextEditingController();

    // Initialize form state if editing
    if (widget.project != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(projectFormProvider.notifier)
            .initializeForEdit(widget.project!);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty) {
      ref.read(projectFormProvider.notifier).addTag(tag);
      _tagController.clear();
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Update form state with current values
    ref
        .read(projectFormProvider.notifier)
        .updateName(_titleController.text.trim());
    ref.read(projectFormProvider.notifier).updateDescription(
          _descriptionController.text.trim(),
        );

    final success = await ref.read(projectFormProvider.notifier).save();

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.project == null
                ? 'Project created successfully'
                : 'Project updated successfully',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.project == null
                ? 'Failed to create project'
                : 'Failed to update project',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(projectFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'Create Project' : 'Edit Project'),
        actions: [
          TextButton(
            onPressed: formState.isSaving ? null : _saveProject,
            child: formState.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Project Title',
                hintText: 'Enter project title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a project title';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter project description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              initialValue: formState.status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'active',
                  child: Row(
                    children: [
                      Icon(Icons.play_circle_outline, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Active'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Completed'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'archived',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Archived'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(projectFormProvider.notifier).updateStatus(value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Tags
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: 'Add a tag',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addTag,
                          icon: const Icon(Icons.add),
                          tooltip: 'Add tag',
                        ),
                      ],
                    ),
                    if (formState.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: formState.tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            onDeleted: () {
                              ref
                                  .read(projectFormProvider.notifier)
                                  .removeTag(tag);
                            },
                            deleteIcon: const Icon(Icons.close, size: 18),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color (Optional)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        '#FF5252',
                        '#E91E63',
                        '#9C27B0',
                        '#673AB7',
                        '#3F51B5',
                        '#2196F3',
                        '#00BCD4',
                        '#009688',
                        '#4CAF50',
                        '#8BC34A',
                        '#CDDC39',
                        '#FFEB3B',
                        '#FFC107',
                        '#FF9800',
                        '#FF5722',
                      ].map((colorHex) {
                        final isSelected = formState.color == colorHex;
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(projectFormProvider.notifier)
                                .updateColor(colorHex);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(colorHex.replaceAll('#', '0xFF')),
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    if (formState.color != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          ref
                              .read(projectFormProvider.notifier)
                              .updateColor(null);
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear color'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon picker (simplified)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Icon (Optional)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        '💼',
                        '🚀',
                        '📊',
                        '🎯',
                        '💡',
                        '🔨',
                        '🎨',
                        '📱',
                        '💻',
                        '📚',
                        '🏆',
                        '⚡',
                      ].map((emoji) {
                        final isSelected = formState.icon == emoji;
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(projectFormProvider.notifier)
                                .updateIcon(emoji);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (formState.icon != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          ref
                              .read(projectFormProvider.notifier)
                              .updateIcon(null);
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear icon'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

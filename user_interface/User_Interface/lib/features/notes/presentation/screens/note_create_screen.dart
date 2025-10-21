import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/note_entity.dart';
import '../providers/note_form_provider.dart';
import '../widgets/tag_chip_list_widget.dart';

class NoteCreateScreen extends ConsumerStatefulWidget {
  const NoteCreateScreen({
    this.existingNote,
    super.key,
  });

  final NoteEntity? existingNote;

  @override
  ConsumerState<NoteCreateScreen> createState() => _NoteCreateScreenState();
}

class _NoteCreateScreenState extends ConsumerState<NoteCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingNote != null) {
        ref
            .read(noteFormProvider.notifier)
            .initializeForEdit(widget.existingNote!);
        _titleController.text = widget.existingNote!.title;
        _contentController.text = widget.existingNote!.content;
      } else {
        ref.read(noteFormProvider.notifier).initializeForCreate();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(noteFormProvider.notifier).save();
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingNote != null
                  ? 'Note updated successfully'
                  : 'Note created successfully',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(noteFormProvider);
    final isEditing = widget.existingNote != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'Create Note'),
        actions: [
          if (formState.isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: formState.isValid ? _save : null,
              tooltip: 'Save note',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter note title',
                  border: OutlineInputBorder(),
                ),
                style: theme.textTheme.titleLarge,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onChanged: (value) {
                  ref.read(noteFormProvider.notifier).updateTitle(value);
                },
              ),
              const SizedBox(height: 16),
              // Content field
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Write your note here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 15,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
                onChanged: (value) {
                  ref.read(noteFormProvider.notifier).updateContent(value);
                },
              ),
              const SizedBox(height: 24),
              // Tags section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TagChipListWidget(
                    tags: formState.tags,
                    onRemoveTag: (tag) {
                      ref.read(noteFormProvider.notifier).removeTag(tag);
                    },
                    onAddTag: (tag) {
                      ref.read(noteFormProvider.notifier).addTag(tag);
                    },
                  ),
                ),
              ),
              // Error message
              if (formState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          formState.error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Save button
              FilledButton.icon(
                onPressed:
                    formState.isValid && !formState.isSaving ? _save : null,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Update Note' : 'Create Note'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

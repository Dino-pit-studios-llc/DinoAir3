import 'package:flutter/material.dart';

class TagChipListWidget extends StatelessWidget {
  const TagChipListWidget({
    required this.tags,
    required this.onRemoveTag,
    required this.onAddTag,
    this.editable = true,
    super.key,
  });

  final List<String> tags;
  final void Function(String tag) onRemoveTag;
  final void Function(String tag) onAddTag;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: theme.textTheme.titleSmall,
            ),
            if (editable) ...[
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddTagDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (tags.isEmpty)
          Text(
            editable ? 'No tags yet. Tap Add to create one.' : 'No tags',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: editable ? () => onRemoveTag(tag) : null,
                deleteIcon: editable
                    ? const Icon(Icons.close, size: 18)
                    : null,
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddTagDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return _AddTagDialog(
          onAddTag: onAddTag,
        );
      },
    );
  }
}

class _AddTagDialog extends StatefulWidget {
  final void Function(String tag) onAddTag;
  const _AddTagDialog({required this.onAddTag});

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Tag'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Tag name',
          hintText: 'Enter tag name',
        ),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            widget.onAddTag(value.trim());
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) {
              widget.onAddTag(value);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

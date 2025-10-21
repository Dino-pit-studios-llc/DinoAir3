import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/calendar_detail_provider.dart';
import '../providers/calendar_form_provider.dart';
import '../providers/calendar_list_provider.dart';
import '../../../notes/presentation/widgets/tag_chip_list_widget.dart';

class CalendarFormScreen extends ConsumerStatefulWidget {
  const CalendarFormScreen({
    this.eventId,
    super.key,
  });

  final String? eventId;

  @override
  ConsumerState<CalendarFormScreen> createState() => _CalendarFormScreenState();
}

class _CalendarFormScreenState extends ConsumerState<CalendarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _initializedFromEvent = false;

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(calendarFormProvider);
    final isEditMode = widget.eventId != null;
    AsyncValue<dynamic>? eventValue;
    if (isEditMode) {
      eventValue = ref.watch(calendarDetailProvider(widget.eventId));
      eventValue?.whenData((event) {
        if (event != null && !_initializedFromEvent) {
          ref.read(calendarFormProvider.notifier).initializeFromEvent(event);
          _initializedFromEvent = true;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Event' : 'New Event'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEvent,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: formState.titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: formState.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: formState.eventType,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'event', child: Text('Event')),
                DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                DropdownMenuItem(value: 'task', child: Text('Task')),
                DropdownMenuItem(value: 'reminder', child: Text('Reminder')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(calendarFormProvider.notifier)
                      .updateEventType(value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: formState.status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                DropdownMenuItem(
                    value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(calendarFormProvider.notifier).updateStatus(value);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Event Date'),
              subtitle: Text(_formatDate(formState.eventDate)),
              leading: const Icon(Icons.event),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: Theme.of(context).dividerColor),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: formState.eventDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  ref
                      .read(calendarFormProvider.notifier)
                      .updateEventDate(picked);
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('All Day Event'),
              value: formState.allDay,
              onChanged: (value) {
                ref.read(calendarFormProvider.notifier).toggleAllDay(value);
              },
            ),
            if (!formState.allDay) ...[
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(
                  formState.startTime != null
                      ? _formatTime(formState.startTime!)
                      : 'Not set',
                ),
                leading: const Icon(Icons.access_time),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: formState.startTime != null
                        ? TimeOfDay.fromDateTime(formState.startTime!)
                        : TimeOfDay.now(),
                  );
                  if (picked != null) {
                    final now = DateTime.now();
                    final dateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      picked.hour,
                      picked.minute,
                    );
                    ref
                        .read(calendarFormProvider.notifier)
                        .updateStartTime(dateTime);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(
                  formState.endTime != null
                      ? _formatTime(formState.endTime!)
                      : 'Not set',
                ),
                leading: const Icon(Icons.access_time),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: formState.endTime != null
                        ? TimeOfDay.fromDateTime(formState.endTime!)
                        : TimeOfDay.now(),
                  );
                  if (picked != null) {
                    final now = DateTime.now();
                    final dateTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      picked.hour,
                      picked.minute,
                    );
                    ref
                        .read(calendarFormProvider.notifier)
                        .updateEndTime(dateTime);
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: formState.locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: formState.recurrencePattern,
              decoration: const InputDecoration(
                labelText: 'Recurrence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Does not repeat')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (value) {
                ref
                    .read(calendarFormProvider.notifier)
                    .updateRecurrencePattern(value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: formState.reminderMinutesBefore,
              decoration: const InputDecoration(
                labelText: 'Reminder',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('No reminder')),
                DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                DropdownMenuItem(value: 60, child: Text('1 hour before')),
                DropdownMenuItem(value: 1440, child: Text('1 day before')),
              ],
              onChanged: (value) {
                ref
                    .read(calendarFormProvider.notifier)
                    .updateReminderMinutes(value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ...formState.participants.map(
                  (participant) => Chip(
                    label: Text(participant),
                    onDeleted: () {
                      ref
                          .read(calendarFormProvider.notifier)
                          .removeParticipant(participant);
                    },
                  ),
                ),
                ActionChip(
                  label: const Text('Add Participant'),
                  avatar: const Icon(Icons.add, size: 18),
                  onPressed: () => _showAddParticipantDialog(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TagChipListWidget(
              tags: formState.tags,
              onAddTag: (tag) {
                ref.read(calendarFormProvider.notifier).addTag(tag);
              },
              onRemoveTag: (tag) {
                ref.read(calendarFormProvider.notifier).removeTag(tag);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: formState.notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildColorPicker(formState),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(CalendarFormState formState) {
    final colors = [
      null, // No color
      '#F44336', // Red
      '#E91E63', // Pink
      '#9C27B0', // Purple
      '#673AB7', // Deep Purple
      '#3F51B5', // Indigo
      '#2196F3', // Blue
      '#03A9F4', // Light Blue
      '#00BCD4', // Cyan
      '#009688', // Teal
      '#4CAF50', // Green
      '#8BC34A', // Light Green
      '#CDDC39', // Lime
      '#FFEB3B', // Yellow
      '#FFC107', // Amber
      '#FF9800', // Orange
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: colors.map((colorHex) {
        final isSelected = formState.color == colorHex;
        return GestureDetector(
          onTap: () {
            ref.read(calendarFormProvider.notifier).updateColor(colorHex);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorHex != null
                  ? Color(
                      int.parse(colorHex.substring(1), radix: 16) + 0xFF000000)
                  : Colors.grey.shade300,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: colorHex == null
                ? const Icon(Icons.block, color: Colors.grey)
                : isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showAddParticipantDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participant'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Email or name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      ref.read(calendarFormProvider.notifier).addParticipant(result);
    }
    controller.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final formState = ref.read(calendarFormProvider);
      final isEditMode = widget.eventId != null;

      if (isEditMode) {
        await ref
            .read(calendarDetailProvider(widget.eventId).notifier)
            .updateEvent(
              id: widget.eventId!,
              title: formState.titleController.text,
              description: formState.descriptionController.text,
              eventType: formState.eventType,
              status: formState.status,
              eventDate: formState.eventDate,
              startTime: formState.startTime,
              endTime: formState.endTime,
              allDay: formState.allDay,
              location: formState.locationController.text.isEmpty
                  ? null
                  : formState.locationController.text,
              participants: formState.participants.isEmpty
                  ? null
                  : formState.participants,
              recurrencePattern: formState.recurrencePattern,
              reminderMinutesBefore: formState.reminderMinutesBefore,
              tags: formState.tags,
              notes: formState.notesController.text.isEmpty
                  ? null
                  : formState.notesController.text,
              color: formState.color,
            );
      } else {
        await ref.read(calendarDetailProvider(null).notifier).createEvent(
              title: formState.titleController.text,
              description: formState.descriptionController.text,
              eventType: formState.eventType,
              status: formState.status,
              eventDate: formState.eventDate,
              startTime: formState.startTime,
              endTime: formState.endTime,
              allDay: formState.allDay,
              location: formState.locationController.text.isEmpty
                  ? null
                  : formState.locationController.text,
              participants: formState.participants.isEmpty
                  ? null
                  : formState.participants,
              recurrencePattern: formState.recurrencePattern,
              reminderMinutesBefore: formState.reminderMinutesBefore,
              tags: formState.tags,
              notes: formState.notesController.text.isEmpty
                  ? null
                  : formState.notesController.text,
              color: formState.color,
            );
      }

      ref.invalidate(calendarListProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode
                ? 'Event updated successfully'
                : 'Event created successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

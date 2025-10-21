import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/calendar_event_entity.dart';
import '../providers/calendar_detail_provider.dart';
import '../providers/calendar_list_provider.dart';
import '../widgets/event_type_indicator_widget.dart';

class CalendarDetailScreen extends ConsumerWidget {
  const CalendarDetailScreen({
    required this.eventId,
    super.key,
  });

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventState = ref.watch(calendarDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/calendar/$eventId/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Event'),
                  content:
                      const Text('Are you sure you want to delete this event?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await ref
                    .read(calendarDetailProvider(eventId).notifier)
                    .deleteEvent(eventId);
                ref.invalidate(calendarListProvider);
                if (context.mounted) {
                  context.pop();
                }
              }
            },
          ),
        ],
      ),
      body: eventState.when(
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Event not found'));
          }
          return _buildEventDetails(context, event);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading event',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context, CalendarEventEntity event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EventTypeIndicatorWidget(eventType: event.eventType),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatusChip(context, event.status),
          const SizedBox(height: 24),
          if (event.description.isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(event.description),
            const SizedBox(height: 24),
          ],
          _buildInfoRow(
            context,
            Icons.event,
            'Date',
            _formatDate(event.eventDate),
          ),
          if (!event.allDay && event.startTime != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Time',
              '${_formatTime(event.startTime!)} - ${event.endTime != null ? _formatTime(event.endTime!) : 'No end time'}',
            ),
          ],
          if (event.allDay) ...[
            const SizedBox(height: 12),
            _buildInfoRow(context, Icons.all_inclusive, 'All Day', 'Yes'),
          ],
          if (event.location != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
                context, Icons.location_on, 'Location', event.location!),
          ],
          if (event.participants != null && event.participants!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Participants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: event.participants!
                  .map((participant) => Chip(label: Text(participant)))
                  .toList(),
            ),
          ],
          if (event.hasRecurrence) ...[
            const SizedBox(height: 24),
            Text(
              'Recurrence',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.repeat,
              'Pattern',
              event.recurrencePattern ?? 'Custom',
            ),
            if (event.recurrenceRule != null) ...[
              const SizedBox(height: 8),
              Text(
                'Rule: ${event.recurrenceRule}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          if (event.hasReminder) ...[
            const SizedBox(height: 24),
            _buildInfoRow(
              context,
              Icons.notifications,
              'Reminder',
              '${event.reminderMinutesBefore} minutes before',
            ),
          ],
          if (event.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: event.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                      ))
                  .toList(),
            ),
          ],
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(event.notes!),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Metadata',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${_formatDateTime(event.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Updated: ${_formatDateTime(event.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (event.completedAt != null)
            Text(
              'Completed: ${_formatDateTime(event.completedAt!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'scheduled':
        backgroundColor = Colors.blue.shade100;
        foregroundColor = Colors.blue.shade900;
        icon = Icons.schedule;
        break;
      case 'in_progress':
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade900;
        icon = Icons.play_circle;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade900;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        foregroundColor = Colors.red.shade900;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        foregroundColor = Colors.grey.shade900;
        icon = Icons.info;
    }

    return Chip(
      avatar: Icon(icon, color: foregroundColor, size: 18),
      label: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.bold),
      ),
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }
}

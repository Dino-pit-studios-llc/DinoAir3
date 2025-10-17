import '../calendar_event_entity.dart';
import '../calendar_event_repository.dart';

class CreateCalendarEventUseCase {
  final CalendarEventRepository repository;

  CreateCalendarEventUseCase(this.repository);

  Future<CalendarEventEntity> call({
    required String title,
    String description = '',
    required String eventType,
    required String status,
    required DateTime eventDate,
    DateTime? startTime,
    DateTime? endTime,
    bool allDay = false,
    String? location,
    List<String>? participants,
    String? projectId,
    String? chatSessionId,
    String? recurrencePattern,
    String? recurrenceRule,
    int? reminderMinutesBefore,
    List<String> tags = const [],
    String? notes,
    String? color,
    Map<String, dynamic>? metadata,
  }) {
    return repository.createEvent(
      title: title,
      description: description,
      eventType: eventType,
      status: status,
      eventDate: eventDate,
      startTime: startTime,
      endTime: endTime,
      allDay: allDay,
      location: location,
      participants: participants,
      projectId: projectId,
      chatSessionId: chatSessionId,
      recurrencePattern: recurrencePattern,
      recurrenceRule: recurrenceRule,
      reminderMinutesBefore: reminderMinutesBefore,
      tags: tags,
      notes: notes,
      color: color,
      metadata: metadata,
    );
  }
}

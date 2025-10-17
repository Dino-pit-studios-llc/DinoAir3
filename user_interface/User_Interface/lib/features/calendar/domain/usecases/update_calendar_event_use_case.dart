import '../calendar_event_entity.dart';
import '../calendar_event_repository.dart';

class UpdateCalendarEventUseCase {
  final CalendarEventRepository repository;

  UpdateCalendarEventUseCase(this.repository);

  Future<CalendarEventEntity> call({
    required String id,
    String? title,
    String? description,
    String? eventType,
    String? status,
    DateTime? eventDate,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? location,
    List<String>? participants,
    String? projectId,
    String? chatSessionId,
    String? recurrencePattern,
    String? recurrenceRule,
    int? reminderMinutesBefore,
    List<String>? tags,
    String? notes,
    String? color,
    Map<String, dynamic>? metadata,
  }) {
    return repository.updateEvent(
      id: id,
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

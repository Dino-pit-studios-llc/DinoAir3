import 'calendar_event_entity.dart';

abstract class CalendarEventRepository {
  /// List all calendar events
  Future<List<CalendarEventEntity>> listEvents();

  /// List events for a specific date
  Future<List<CalendarEventEntity>> listEventsByDate(DateTime date);

  /// List events within a date range
  Future<List<CalendarEventEntity>> listEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get a specific calendar event by ID
  Future<CalendarEventEntity> getEvent(String id);

  /// Create a new calendar event
  Future<CalendarEventEntity> createEvent({
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
  });

  /// Update an existing calendar event
  Future<CalendarEventEntity> updateEvent({
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
  });

  /// Delete a calendar event
  Future<void> deleteEvent(String id);

  /// Search events by query (title, description, location)
  Future<List<CalendarEventEntity>> searchEvents(String query);

  /// Filter events by type
  Future<List<CalendarEventEntity>> filterByType(String eventType);

  /// Filter events by status
  Future<List<CalendarEventEntity>> filterByStatus(String status);
}

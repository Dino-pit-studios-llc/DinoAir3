import 'calendar_event_entity.dart';

/// Repository interface for calendar event management operations.
///
/// This repository defines the contract for all calendar-related data operations,
/// supporting event CRUD, date-based queries, search, and filtering.
///
/// ## Responsibilities
/// - CRUD operations for calendar events
/// - Date-based event querying (single date, date range)
/// - Full-text search across event properties
/// - Filtering by event type and status
/// - Support for recurring events and reminders
///
/// ## Event Types
/// Common event types include:
/// - `meeting`: Team meetings, client calls
/// - `deadline`: Project deadlines, deliverables
/// - `reminder`: General reminders
/// - `task`: Time-blocked tasks
/// - `personal`: Personal events
///
/// ## Event Statuses
/// - `scheduled`: Upcoming event
/// - `in_progress`: Currently happening
/// - `completed`: Finished event
/// - `cancelled`: Cancelled event
///
/// ## Usage Example
/// ```dart
/// // Create meeting
/// final meeting = await repository.createEvent(
///   title: 'Sprint Planning',
///   eventType: 'meeting',
///   status: 'scheduled',
///   eventDate: DateTime(2025, 1, 15),
///   startTime: DateTime(2025, 1, 15, 10, 0),
///   endTime: DateTime(2025, 1, 15, 11, 0),
///   participants: ['john@example.com', 'jane@example.com'],
///   reminderMinutesBefore: 15,
/// );
///
/// // Query events for today
/// final today = DateTime.now();
/// final todayEvents = await repository.listEventsByDate(today);
/// ```
///
/// ## Error Handling
/// Operations may throw:
/// - `ServerException`: Backend server errors
/// - `NetworkException`: Network connectivity issues
/// - `NotFoundException`: Event not found
/// - `ValidationException`: Invalid event data
///
/// See also:
/// - [CalendarEventEntity]: Domain entity representing an event
/// - [CreateCalendarEventUseCase]: Use case for creating events
/// - [ListEventsUseCase]: Use case for listing events
abstract class CalendarEventRepository {
  /// Retrieves all calendar events from the data source.
  ///
  /// Returns all events sorted by event date (ascending).
  /// Use date-based queries for better performance.
  ///
  /// Example:
  /// ```dart
  /// final allEvents = await repository.listEvents();
  /// print('Total events: ${allEvents.length}');
  /// ```
  ///
  /// Throws:
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<List<CalendarEventEntity>> listEvents();

  /// Lists all events occurring on a specific date.
  ///
  /// Matches events where [date] falls between startTime and endTime,
  /// or where eventDate equals [date] for all-day events.
  ///
  /// Parameters:
  /// - [date]: The date to query (time component ignored)
  ///
  /// Returns events for the specified date, sorted by startTime.
  ///
  /// Example:
  /// ```dart
  /// final today = DateTime.now();
  /// final todayEvents = await repository.listEventsByDate(today);
  ///
  /// for (final event in todayEvents) {
  ///   print('${event.startTime?.hour}:${event.startTime?.minute} - ${event.title}');
  /// }
  /// ```
  ///
  /// Throws:
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<List<CalendarEventEntity>> listEventsByDate(DateTime date);

  /// Lists all events within a date range (inclusive).
  ///
  /// Matches events where eventDate or startTime falls between
  /// [startDate] and [endDate].
  ///
  /// Parameters:
  /// - [startDate]: Range start date (inclusive)
  /// - [endDate]: Range end date (inclusive)
  ///
  /// Returns events within the date range, sorted by eventDate/startTime.
  ///
  /// Example:
  /// ```dart
  /// // Get this week's events
  /// final now = DateTime.now();
  /// final weekStart = now.subtract(Duration(days: now.weekday - 1));
  /// final weekEnd = weekStart.add(const Duration(days: 6));
  ///
  /// final weekEvents = await repository.listEventsByDateRange(
  ///   startDate: weekStart,
  ///   endDate: weekEnd,
  /// );
  /// print('This week: ${weekEvents.length} events');
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if startDate is after endDate
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<List<CalendarEventEntity>> listEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Retrieves a specific calendar event by its unique identifier.
  ///
  /// Parameters:
  /// - [id]: The unique identifier of the event (UUID format)
  ///
  /// Returns the event entity if found.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final event = await repository.getEvent(eventId);
  ///   print('Event: ${event.title} on ${event.eventDate}');
  /// } on NotFoundException {
  ///   print('Event not found');
  /// }
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if id is empty or invalid
  /// - [NotFoundException] if event does not exist
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<CalendarEventEntity> getEvent(String id);

  /// Creates a new calendar event.
  ///
  /// Parameters:
  /// - [title]: Event title (required, non-empty)
  /// - [description]: Detailed description (default: '')
  /// - [eventType]: Type of event (meeting, deadline, etc.)
  /// - [status]: Current status (scheduled, completed, etc.)
  /// - [eventDate]: Primary event date (required)
  /// - [startTime]: Event start date-time (optional for all-day)
  /// - [endTime]: Event end date-time (optional for all-day)
  /// - [allDay]: Whether event is all-day (default: false)
  /// - [location]: Physical or virtual location
  /// - [participants]: List of participant emails
  /// - [projectId]: Associated project ID
  /// - [chatSessionId]: Associated chat session ID
  /// - [recurrencePattern]: Recurrence pattern (daily, weekly, etc.)
  /// - [recurrenceRule]: iCal recurrence rule (RRULE)
  /// - [reminderMinutesBefore]: Minutes before event to remind
  /// - [tags]: List of tags for categorization
  /// - [notes]: Additional notes
  /// - [color]: Event color (hex code)
  /// - [metadata]: Additional custom metadata
  ///
  /// Returns the created event with server-generated id and timestamps.
  ///
  /// Example:
  /// ```dart
  /// final meeting = await repository.createEvent(
  ///   title: 'Product Review',
  ///   description: 'Q1 product roadmap review',
  ///   eventType: 'meeting',
  ///   status: 'scheduled',
  ///   eventDate: DateTime(2025, 1, 20),
  ///   startTime: DateTime(2025, 1, 20, 14, 0),
  ///   endTime: DateTime(2025, 1, 20, 15, 30),
  ///   location: 'Conference Room A',
  ///   participants: ['alice@example.com', 'bob@example.com'],
  ///   reminderMinutesBefore: 30,
  ///   tags: ['quarterly', 'product'],
  /// );
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if required fields missing or invalid
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
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

  /// Updates an existing calendar event.
  ///
  /// Only provided parameters are updated; null values are ignored.
  ///
  /// Parameters:
  /// - [id]: Event ID to update (required)
  /// - All other parameters optional (only non-null values updated)
  ///
  /// Returns the updated event with new updatedAt timestamp.
  ///
  /// Example:
  /// ```dart
  /// // Reschedule meeting
  /// final updated = await repository.updateEvent(
  ///   id: eventId,
  ///   startTime: DateTime(2025, 1, 21, 10, 0),
  ///   endTime: DateTime(2025, 1, 21, 11, 30),
  ///   participants: ['alice@example.com', 'bob@example.com', 'charlie@example.com'],
  /// );
  ///
  /// // Mark as completed
  /// await repository.updateEvent(
  ///   id: eventId,
  ///   status: 'completed',
  /// );
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if id missing or data invalid
  /// - [NotFoundException] if event does not exist
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
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

  /// Deletes a calendar event.
  ///
  /// This operation is idempotent - deleting non-existent event succeeds.
  ///
  /// Parameters:
  /// - [id]: The unique identifier of the event to delete
  ///
  /// Example:
  /// ```dart
  /// await repository.deleteEvent(eventId);
  /// print('Event deleted');
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if id is empty or invalid
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<void> deleteEvent(String id);

  /// Searches events by query text.
  ///
  /// Performs full-text search on title, description, and location fields.
  ///
  /// Parameters:
  /// - [query]: Search query text (non-empty)
  ///
  /// Returns matching events sorted by relevance.
  ///
  /// Example:
  /// ```dart
  /// final results = await repository.searchEvents('team meeting');
  /// print('Found ${results.length} matching events');
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if query is empty
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<List<CalendarEventEntity>> searchEvents(String query);

  /// Filters events by event type.
  ///
  /// Parameters:
  /// - [eventType]: Event type to filter by (e.g., 'meeting', 'deadline')
  ///
  /// Returns events matching the specified type.
  ///
  /// Example:
  /// ```dart
  /// final meetings = await repository.filterByType('meeting');
  /// final deadlines = await repository.filterByType('deadline');
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if eventType is empty
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<List<CalendarEventEntity>> filterByType(String eventType);

  /// Filters events by status.
  ///
  /// Parameters:
  /// - [status]: Status to filter by (e.g., 'scheduled', 'completed')
  ///
  /// Returns events matching the specified status.
  ///
  /// Example:
  /// ```dart
  /// final upcoming = await repository.filterByStatus('scheduled');
  /// final completed = await repository.filterByStatus('completed');
  /// ```
  ///
  /// Throws:
  /// - [ValidationException] if status is empty
  /// - [ServerException] if backend returns error
  /// - [NetworkException] if network request fails
  Future<List<CalendarEventEntity>> filterByStatus(String status);
}

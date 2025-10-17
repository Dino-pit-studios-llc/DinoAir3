import '../../domain/calendar_event_entity.dart';
import '../../domain/calendar_event_repository.dart';
import '../datasources/calendar_remote_data_source.dart';
import '../mappers/calendar_event_mapper.dart';

class CalendarEventRepositoryImpl implements CalendarEventRepository {
  const CalendarEventRepositoryImpl({
    required CalendarRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final CalendarRemoteDataSource _remoteDataSource;

  @override
  Future<List<CalendarEventEntity>> listEvents() async {
    final dtos = await _remoteDataSource.listEvents();
    return dtos.map((dto) => CalendarEventMapper.toEntity(dto)).toList();
  }

  @override
  Future<List<CalendarEventEntity>> listEventsByDate(DateTime date) async {
    final dtos = await _remoteDataSource.listEvents(
      startDate: date,
      endDate: date,
    );
    return dtos.map((dto) => CalendarEventMapper.toEntity(dto)).toList();
  }

  @override
  Future<List<CalendarEventEntity>> listEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dtos = await _remoteDataSource.listEvents(
      startDate: startDate,
      endDate: endDate,
    );
    return dtos.map((dto) => CalendarEventMapper.toEntity(dto)).toList();
  }

  @override
  Future<CalendarEventEntity> getEvent(String id) async {
    final dto = await _remoteDataSource.getEvent(id);
    return CalendarEventMapper.toEntity(dto);
  }

  @override
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
  }) async {
    final dto = await _remoteDataSource.createEvent(
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
    return CalendarEventMapper.toEntity(dto);
  }

  @override
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
  }) async {
    final dto = await _remoteDataSource.updateEvent(
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
    return CalendarEventMapper.toEntity(dto);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _remoteDataSource.deleteEvent(id);
  }

  @override
  Future<List<CalendarEventEntity>> searchEvents(String query) async {
    // For now, fetch all and filter locally
    // Can be optimized with backend search endpoint later
    final events = await listEvents();
    final lowercaseQuery = query.toLowerCase();
    return events
        .where((event) =>
            event.title.toLowerCase().contains(lowercaseQuery) ||
            event.description.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  @override
  Future<List<CalendarEventEntity>> filterByType(String eventType) async {
    final dtos = await _remoteDataSource.listEvents(eventType: eventType);
    return dtos.map((dto) => CalendarEventMapper.toEntity(dto)).toList();
  }

  @override
  Future<List<CalendarEventEntity>> filterByStatus(String status) async {
    final dtos = await _remoteDataSource.listEvents(status: status);
    return dtos.map((dto) => CalendarEventMapper.toEntity(dto)).toList();
  }
}

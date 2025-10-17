import 'package:dio/dio.dart';
import '../models/calendar_event_dto.dart';

class CalendarRemoteDataSource {
  CalendarRemoteDataSource({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

  Future<List<CalendarEventDto>> listEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
    }
    if (eventType != null) {
      queryParams['event_type'] = eventType;
    }
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _dio.get(
      '$_baseUrl/calendar/',
      queryParameters: queryParams,
    );
    final data = response.data as List<dynamic>;
    return data.map((json) => CalendarEventDto.fromJson(json)).toList();
  }

  Future<CalendarEventDto> getEvent(String id) async {
    final response = await _dio.get('$_baseUrl/calendar/$id');
    return CalendarEventDto.fromJson(response.data);
  }

  Future<CalendarEventDto> createEvent({
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
    final body = {
      'title': title,
      'description': description,
      'event_type': eventType,
      'status': status,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'all_day': allDay,
      'tags': tags,
      if (startTime != null)
        'start_time': startTime.toIso8601String().split('T')[1],
      if (endTime != null) 'end_time': endTime.toIso8601String().split('T')[1],
      if (location != null) 'location': location,
      if (participants != null) 'participants': participants,
      if (projectId != null) 'project_id': projectId,
      if (chatSessionId != null) 'chat_session_id': chatSessionId,
      if (recurrencePattern != null) 'recurrence_pattern': recurrencePattern,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (reminderMinutesBefore != null)
        'reminder_minutes_before': reminderMinutesBefore,
      if (notes != null) 'notes': notes,
      if (color != null) 'color': color,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await _dio.post('$_baseUrl/calendar/', data: body);
    return CalendarEventDto.fromJson(response.data);
  }

  Future<CalendarEventDto> updateEvent({
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
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (eventType != null) body['event_type'] = eventType;
    if (status != null) body['status'] = status;
    if (eventDate != null) {
      body['event_date'] = eventDate.toIso8601String().split('T')[0];
    }
    if (startTime != null) {
      body['start_time'] = startTime.toIso8601String().split('T')[1];
    }
    if (endTime != null) {
      body['end_time'] = endTime.toIso8601String().split('T')[1];
    }
    if (allDay != null) body['all_day'] = allDay;
    if (location != null) body['location'] = location;
    if (participants != null) body['participants'] = participants;
    if (projectId != null) body['project_id'] = projectId;
    if (chatSessionId != null) body['chat_session_id'] = chatSessionId;
    if (recurrencePattern != null) {
      body['recurrence_pattern'] = recurrencePattern;
    }
    if (recurrenceRule != null) body['recurrence_rule'] = recurrenceRule;
    if (reminderMinutesBefore != null) {
      body['reminder_minutes_before'] = reminderMinutesBefore;
    }
    if (tags != null) body['tags'] = tags;
    if (notes != null) body['notes'] = notes;
    if (color != null) body['color'] = color;
    if (metadata != null) body['metadata'] = metadata;

    final response = await _dio.put('$_baseUrl/calendar/$id', data: body);
    return CalendarEventDto.fromJson(response.data);
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete('$_baseUrl/calendar/$id');
  }
}

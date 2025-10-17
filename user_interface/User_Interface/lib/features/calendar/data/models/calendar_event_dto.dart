class CalendarEventDto {
  const CalendarEventDto({
    required this.id,
    required this.title,
    required this.description,
    required this.eventType,
    required this.status,
    required this.eventDate,
    this.startTime,
    this.endTime,
    required this.allDay,
    this.location,
    this.participants,
    this.projectId,
    this.chatSessionId,
    this.recurrencePattern,
    this.recurrenceRule,
    this.reminderMinutesBefore,
    required this.reminderSent,
    required this.tags,
    this.notes,
    this.color,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final String eventType;
  final String status;
  final String eventDate;
  final String? startTime;
  final String? endTime;
  final bool allDay;
  final String? location;
  final List<String>? participants;
  final String? projectId;
  final String? chatSessionId;
  final String? recurrencePattern;
  final String? recurrenceRule;
  final int? reminderMinutesBefore;
  final bool reminderSent;
  final List<String> tags;
  final String? notes;
  final String? color;
  final Map<String, dynamic>? metadata;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;

  factory CalendarEventDto.fromJson(Map<String, dynamic> json) {
    return CalendarEventDto(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      eventType: json['event_type'] as String,
      status: json['status'] as String,
      eventDate: json['event_date'] as String,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      allDay: json['all_day'] as bool? ?? false,
      location: json['location'] as String?,
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      projectId: json['project_id'] as String?,
      chatSessionId: json['chat_session_id'] as String?,
      recurrencePattern: json['recurrence_pattern'] as String?,
      recurrenceRule: json['recurrence_rule'] as String?,
      reminderMinutesBefore: json['reminder_minutes_before'] as int?,
      reminderSent: json['reminder_sent'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      notes: json['notes'] as String?,
      color: json['color'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      completedAt: json['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'event_type': eventType,
      'status': status,
      'event_date': eventDate,
      'start_time': startTime,
      'end_time': endTime,
      'all_day': allDay,
      'location': location,
      'participants': participants,
      'project_id': projectId,
      'chat_session_id': chatSessionId,
      'recurrence_pattern': recurrencePattern,
      'recurrence_rule': recurrenceRule,
      'reminder_minutes_before': reminderMinutesBefore,
      'reminder_sent': reminderSent,
      'tags': tags,
      'notes': notes,
      'color': color,
      'metadata': metadata,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'completed_at': completedAt,
    };
  }
}

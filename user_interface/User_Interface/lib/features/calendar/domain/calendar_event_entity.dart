import 'package:meta/meta.dart';

@immutable
class CalendarEventEntity {
  const CalendarEventEntity({
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
  final String eventType; // 'meeting', 'task', 'reminder', 'event'
  final String status; // 'scheduled', 'completed', 'cancelled'
  final DateTime eventDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool allDay;
  final String? location;
  final List<String>? participants;
  final String? projectId;
  final String? chatSessionId;
  final String? recurrencePattern; // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  final String? recurrenceRule;
  final int? reminderMinutesBefore;
  final bool reminderSent;
  final List<String> tags;
  final String? notes;
  final String? color;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  // Computed properties
  bool get isScheduled => status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isMeeting => eventType == 'meeting';
  bool get isTask => eventType == 'task';
  bool get isReminder => eventType == 'reminder';
  bool get isEvent => eventType == 'event';

  bool get hasReminder => reminderMinutesBefore != null;
  bool get hasRecurrence => recurrencePattern != null && recurrencePattern != 'none';
  bool get isLinkedToProject => projectId != null && projectId!.isNotEmpty;

  /// Check if event is multi-day
  bool get isMultiDay {
    if (startTime == null || endTime == null) return false;
    return !_isSameDay(startTime!, endTime!);
  }

  /// Get duration in minutes
  int? get durationMinutes {
    if (startTime == null || endTime == null) return null;
    return endTime!.difference(startTime!).inMinutes;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  CalendarEventEntity copyWith({
    String? id,
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
    bool? reminderSent,
    List<String>? tags,
    String? notes,
    String? color,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return CalendarEventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      participants: participants ?? this.participants,
      projectId: projectId ?? this.projectId,
      chatSessionId: chatSessionId ?? this.chatSessionId,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      reminderSent: reminderSent ?? this.reminderSent,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEventEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

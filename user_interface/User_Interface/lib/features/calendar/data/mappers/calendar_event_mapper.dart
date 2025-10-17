import '../../domain/calendar_event_entity.dart';
import '../models/calendar_event_dto.dart';

class CalendarEventMapper {
  static CalendarEventEntity toEntity(CalendarEventDto dto) {
    return CalendarEventEntity(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      eventType: dto.eventType,
      status: dto.status,
      eventDate: DateTime.parse(dto.eventDate),
      startTime: dto.startTime != null ? DateTime.parse(dto.startTime!) : null,
      endTime: dto.endTime != null ? DateTime.parse(dto.endTime!) : null,
      allDay: dto.allDay,
      location: dto.location,
      participants: dto.participants,
      projectId: dto.projectId,
      chatSessionId: dto.chatSessionId,
      recurrencePattern: dto.recurrencePattern,
      recurrenceRule: dto.recurrenceRule,
      reminderMinutesBefore: dto.reminderMinutesBefore,
      reminderSent: dto.reminderSent,
      tags: dto.tags,
      notes: dto.notes,
      color: dto.color,
      metadata: dto.metadata,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: DateTime.parse(dto.updatedAt),
      completedAt:
          dto.completedAt != null ? DateTime.parse(dto.completedAt!) : null,
    );
  }

  static CalendarEventDto toDto(CalendarEventEntity entity) {
    return CalendarEventDto(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      eventType: entity.eventType,
      status: entity.status,
      eventDate: entity.eventDate.toIso8601String(),
      startTime: entity.startTime?.toIso8601String(),
      endTime: entity.endTime?.toIso8601String(),
      allDay: entity.allDay,
      location: entity.location,
      participants: entity.participants,
      projectId: entity.projectId,
      chatSessionId: entity.chatSessionId,
      recurrencePattern: entity.recurrencePattern,
      recurrenceRule: entity.recurrenceRule,
      reminderMinutesBefore: entity.reminderMinutesBefore,
      reminderSent: entity.reminderSent,
      tags: entity.tags,
      notes: entity.notes,
      color: entity.color,
      metadata: entity.metadata,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      completedAt: entity.completedAt?.toIso8601String(),
    );
  }
}

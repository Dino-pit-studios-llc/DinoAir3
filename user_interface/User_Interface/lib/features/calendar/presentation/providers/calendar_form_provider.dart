import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/calendar_event_entity.dart';

final calendarFormProvider =
    StateNotifierProvider.autoDispose<CalendarFormNotifier, CalendarFormState>(
  (ref) => CalendarFormNotifier(),
);

class CalendarFormState {
  const CalendarFormState({
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
    required this.notesController,
    required this.eventType,
    required this.status,
    required this.eventDate,
    this.startTime,
    this.endTime,
    required this.allDay,
    required this.participants,
    this.projectId,
    this.recurrencePattern,
    this.recurrenceRule,
    this.reminderMinutesBefore,
    required this.tags,
    this.color,
    this.metadata,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController notesController;
  final String eventType;
  final String status;
  final DateTime eventDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool allDay;
  final List<String> participants;
  final String? projectId;
  final String? recurrencePattern;
  final String? recurrenceRule;
  final int? reminderMinutesBefore;
  final List<String> tags;
  final String? color;
  final Map<String, dynamic>? metadata;

  CalendarFormState copyWith({
    TextEditingController? titleController,
    TextEditingController? descriptionController,
    TextEditingController? locationController,
    TextEditingController? notesController,
    String? eventType,
    String? status,
    DateTime? eventDate,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    List<String>? participants,
    String? projectId,
    String? recurrencePattern,
    String? recurrenceRule,
    int? reminderMinutesBefore,
    List<String>? tags,
    String? color,
    Map<String, dynamic>? metadata,
  }) {
    return CalendarFormState(
      titleController: titleController ?? this.titleController,
      descriptionController:
          descriptionController ?? this.descriptionController,
      locationController: locationController ?? this.locationController,
      notesController: notesController ?? this.notesController,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      participants: participants ?? this.participants,
      projectId: projectId ?? this.projectId,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
    );
  }
}

class CalendarFormNotifier extends StateNotifier<CalendarFormState> {
  CalendarFormNotifier()
      : super(CalendarFormState(
          titleController: TextEditingController(),
          descriptionController: TextEditingController(),
          locationController: TextEditingController(),
          notesController: TextEditingController(),
          eventType: 'event',
          status: 'scheduled',
          eventDate: DateTime.now(),
          allDay: false,
          participants: [],
          tags: [],
        ));

  void initializeFromEvent(CalendarEventEntity event) {
    state.titleController.text = event.title;
    state.descriptionController.text = event.description;
    state.locationController.text = event.location ?? '';
    state.notesController.text = event.notes ?? '';

    state = state.copyWith(
      eventType: event.eventType,
      status: event.status,
      eventDate: event.eventDate,
      startTime: event.startTime,
      endTime: event.endTime,
      allDay: event.allDay,
      participants: List.from(event.participants ?? []),
      projectId: event.projectId,
      recurrencePattern: event.recurrencePattern,
      recurrenceRule: event.recurrenceRule,
      reminderMinutesBefore: event.reminderMinutesBefore,
      tags: List.from(event.tags),
      color: event.color,
      metadata: event.metadata != null ? Map.from(event.metadata!) : null,
    );
  }

  void updateEventType(String eventType) {
    state = state.copyWith(eventType: eventType);
  }

  void updateStatus(String status) {
    state = state.copyWith(status: status);
  }

  void updateEventDate(DateTime date) {
    state = state.copyWith(eventDate: date);
  }

  void updateStartTime(DateTime? time) {
    state = state.copyWith(startTime: time);
  }

  void updateEndTime(DateTime? time) {
    state = state.copyWith(endTime: time);
  }

  void toggleAllDay(bool allDay) {
    state = state.copyWith(allDay: allDay);
  }

  void addParticipant(String participant) {
    final updatedParticipants = [...state.participants, participant];
    state = state.copyWith(participants: updatedParticipants);
  }

  void removeParticipant(String participant) {
    final updatedParticipants = state.participants
        .where((p) => p != participant)
        .toList();
    state = state.copyWith(participants: updatedParticipants);
  }

  void updateProjectId(String? projectId) {
    state = state.copyWith(projectId: projectId);
  }

  void updateRecurrencePattern(String? pattern) {
    state = state.copyWith(recurrencePattern: pattern);
  }

  void updateRecurrenceRule(String? rule) {
    state = state.copyWith(recurrenceRule: rule);
  }

  void updateReminderMinutes(int? minutes) {
    state = state.copyWith(reminderMinutesBefore: minutes);
  }

  void addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) {
      return;
    }
    if (!state.tags.contains(trimmedTag)) {
      final updatedTags = [...state.tags, trimmedTag];
      state = state.copyWith(tags: updatedTags);
    }
  }

  void removeTag(String tag) {
    final updatedTags = state.tags.where((t) => t != tag).toList();
    state = state.copyWith(tags: updatedTags);
  }

  void updateColor(String? color) {
    state = state.copyWith(color: color);
  }

  void updateMetadata(Map<String, dynamic>? metadata) {
    state = state.copyWith(metadata: metadata);
  }

  @override
  void dispose() {
    state.titleController.dispose();
    state.descriptionController.dispose();
    state.locationController.dispose();
    state.notesController.dispose();
    super.dispose();
  }
}

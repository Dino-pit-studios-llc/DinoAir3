import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/calendar_event_entity.dart';
import '../../domain/usecases/create_calendar_event_use_case.dart';
import '../../domain/usecases/delete_calendar_event_use_case.dart';
import '../../domain/usecases/get_calendar_event_use_case.dart';
import '../../domain/usecases/update_calendar_event_use_case.dart';
import 'calendar_repository_provider.dart';

final calendarDetailProvider = AsyncNotifierProviderFamily<
    CalendarDetailNotifier,
    CalendarEventEntity?,
    String?>(() => CalendarDetailNotifier());

class CalendarDetailNotifier
    extends FamilyAsyncNotifier<CalendarEventEntity?, String?> {
  late final GetCalendarEventUseCase _getEventUseCase;
  late final CreateCalendarEventUseCase _createEventUseCase;
  late final UpdateCalendarEventUseCase _updateEventUseCase;
  late final DeleteCalendarEventUseCase _deleteEventUseCase;

  @override
  Future<CalendarEventEntity?> build(String? arg) async {
    final repository = ref.watch(calendarRepositoryProvider);
    _getEventUseCase = GetCalendarEventUseCase(repository);
    _createEventUseCase = CreateCalendarEventUseCase(repository);
    _updateEventUseCase = UpdateCalendarEventUseCase(repository);
    _deleteEventUseCase = DeleteCalendarEventUseCase(repository);

    if (arg == null || arg.isEmpty) {
      return null; // New event mode
    }

    return _getEventUseCase(arg);
  }

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
    final event = await _createEventUseCase(
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

    state = AsyncValue.data(event);
    return event;
  }

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
    final event = await _updateEventUseCase(
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

    state = AsyncValue.data(event);
    return event;
  }

  Future<void> deleteEvent(String id) async {
    await _deleteEventUseCase(id);
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() async {
    if (arg == null || arg!.isEmpty) {
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _getEventUseCase(arg!);
    });
  }
}

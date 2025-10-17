import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/calendar_event_entity.dart';
import '../../domain/usecases/delete_calendar_event_use_case.dart';
import '../../domain/usecases/list_calendar_events_use_case.dart';
import '../../domain/usecases/list_events_by_date_range_use_case.dart';
import 'calendar_repository_provider.dart';

final calendarListProvider =
    AsyncNotifierProvider<CalendarListNotifier, List<CalendarEventEntity>>(
  () => CalendarListNotifier(),
);

class CalendarListNotifier extends AsyncNotifier<List<CalendarEventEntity>> {
  late final ListCalendarEventsUseCase _listEventsUseCase;
  late final ListEventsByDateRangeUseCase _listByDateRangeUseCase;
  late final DeleteCalendarEventUseCase _deleteEventUseCase;

  @override
  Future<List<CalendarEventEntity>> build() async {
    final repository = ref.watch(calendarRepositoryProvider);
    _listEventsUseCase = ListCalendarEventsUseCase(repository);
    _listByDateRangeUseCase = ListEventsByDateRangeUseCase(repository);
    _deleteEventUseCase = DeleteCalendarEventUseCase(repository);

    return _listEventsUseCase();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _listEventsUseCase();
    });
  }

  Future<void> loadEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _listByDateRangeUseCase(
        startDate: startDate,
        endDate: endDate,
      );
    });
  }

  Future<void> loadEventsByType(String eventType) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(calendarRepositoryProvider);
      return repository.filterByType(eventType);
    });
  }

  Future<void> loadEventsByStatus(String status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(calendarRepositoryProvider);
      return repository.filterByStatus(status);
    });
  }

  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      await refresh();
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(calendarRepositoryProvider);
      return repository.searchEvents(query);
    });
  }

  Future<void> deleteEvent(String id) async {
    await _deleteEventUseCase(id);
    await refresh();
  }
}

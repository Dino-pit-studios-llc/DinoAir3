import '../calendar_event_entity.dart';
import '../calendar_event_repository.dart';

class ListCalendarEventsUseCase {
  final CalendarEventRepository repository;

  ListCalendarEventsUseCase(this.repository);

  Future<List<CalendarEventEntity>> call() {
    return repository.listEvents();
  }
}

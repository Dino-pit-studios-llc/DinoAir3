import '../calendar_event_entity.dart';
import '../calendar_event_repository.dart';

class ListEventsByDateRangeUseCase {
  final CalendarEventRepository repository;

  ListEventsByDateRangeUseCase(this.repository);

  Future<List<CalendarEventEntity>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.listEventsByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }
}

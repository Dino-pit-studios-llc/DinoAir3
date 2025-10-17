import '../calendar_event_entity.dart';
import '../calendar_event_repository.dart';

class GetCalendarEventUseCase {
  final CalendarEventRepository repository;

  GetCalendarEventUseCase(this.repository);

  Future<CalendarEventEntity> call(String id) {
    return repository.getEvent(id);
  }
}
